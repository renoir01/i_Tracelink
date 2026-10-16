const { readFileSync } = require('node:fs');
const path = require('node:path');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  deleteDoc,
  Timestamp,
} = require('firebase/firestore');

const PROJECT_ID = 'itracelink-rules-test';
const RULES = readFileSync(path.join(__dirname, '../../firestore.rules'), 'utf8');
let testEnv;

const stamp = () => Timestamp.fromDate(new Date('2026-01-01T10:00:00.000Z'));

function orderData(overrides = {}) {
  return {
    orderType: 'beans',
    buyerId: 'buyer-1',
    sellerId: 'seller-1',
    quantity: 10,
    pricePerKg: 100,
    totalAmount: 1000,
    requestDate: stamp(),
    expectedDeliveryDate: stamp(),
    status: 'pending',
    deliveryLocation: { district: 'Ngoma', sector: 'Rurenge', cell: 'Cell A' },
    paymentStatus: 'pending',
    ...overrides,
  };
}

async function seed(pathName, data) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), pathName), data);
  });
}

async function seedOrder(status = 'pending', paymentStatus = 'pending') {
  await seed('orders/order-1', orderData({ status, paymentStatus }));
}

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules: RULES },
  });
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

after(async () => {
  await testEnv.cleanup();
});

test('users can read their own profile but not another profile', async () => {
  await seed('users/user-1', {
    userType: 'farmer', name: 'Farmer One',
    email: 'farmer@example.com', phone: '0780000000', isVerified: false,
  });
  const ownerDb = testEnv.authenticatedContext('user-1', {
    email: 'farmer@example.com',
  }).firestore();
  const otherDb = testEnv.authenticatedContext('user-2', {
    email: 'other@example.com',
  }).firestore();

  await assertSucceeds(getDoc(doc(ownerDb, 'users/user-1')));
  await assertFails(getDoc(doc(otherDb, 'users/user-1')));
});

test('an active admin can read profiles, but an ordinary user cannot', async () => {
  await seed('users/user-1', {
    userType: 'farmer', name: 'Farmer One',
    email: 'farmer@example.com', isVerified: false,
  });
  await seed('admins/admin@example.com', { isActive: true });

  const adminDb = testEnv.authenticatedContext('admin-1', {
    email: 'admin@example.com',
  }).firestore();
  const ordinaryDb = testEnv.authenticatedContext('ordinary-1', {
    email: 'ordinary@example.com',
  }).firestore();

  await assertSucceeds(getDoc(doc(adminDb, 'users/user-1')));
  await assertFails(getDoc(doc(ordinaryDb, 'users/user-1')));
});

test('a buyer can create a valid pending order', async () => {
  const buyerDb = testEnv.authenticatedContext('buyer-1', {
    email: 'buyer@example.com',
  }).firestore();
  await assertSucceeds(setDoc(doc(buyerDb, 'orders/new-order'), orderData()));
});

test('order creation rejects forged buyer, altered totals, and non-pending status', async () => {
  const buyerDb = testEnv.authenticatedContext('buyer-1', {
    email: 'buyer@example.com',
  }).firestore();

  await assertFails(setDoc(doc(buyerDb, 'orders/forged-buyer'),
    orderData({ buyerId: 'someone-else' })));
  await assertFails(setDoc(doc(buyerDb, 'orders/forged-total'),
    orderData({ totalAmount: 5 })));
  await assertFails(setDoc(doc(buyerDb, 'orders/preaccepted'),
    orderData({ status: 'accepted' })));
  await assertFails(setDoc(doc(buyerDb, 'orders/self-order'),
    orderData({ sellerId: 'buyer-1' })));
});

test('seller can accept a pending order', async () => {
  await seedOrder();
  const sellerDb = testEnv.authenticatedContext('seller-1', {
    email: 'seller@example.com',
  }).firestore();
  await assertSucceeds(updateDoc(doc(sellerDb, 'orders/order-1'), {
    status: 'accepted',
    updatedAt: stamp(),
    acceptedAt: stamp(),
  }));
});

test('order updates reject financial tampering and invalid role transitions', async () => {
  await seedOrder();
  const sellerDb = testEnv.authenticatedContext('seller-1', {
    email: 'seller@example.com',
  }).firestore();
  const buyerDb = testEnv.authenticatedContext('buyer-1', {
    email: 'buyer@example.com',
  }).firestore();

  await assertFails(updateDoc(doc(sellerDb, 'orders/order-1'), {
    status: 'accepted',
    totalAmount: 1,
    updatedAt: stamp(),
    acceptedAt: stamp(),
  }));
  await assertFails(updateDoc(doc(buyerDb, 'orders/order-1'), {
    status: 'accepted',
    updatedAt: stamp(),
    acceptedAt: stamp(),
  }));
  await assertFails(updateDoc(doc(sellerDb, 'orders/order-1'), {
    status: 'accepted',
    paymentStatus: 'paid',
    updatedAt: stamp(),
    acceptedAt: stamp(),
  }));
});

test('payment creation is allowed only for the buyer on an accepted order with matching amount', async () => {
  await seedOrder('accepted', 'pending');
  const buyerDb = testEnv.authenticatedContext('buyer-1', {
    email: 'buyer@example.com',
  }).firestore();

  const validPayment = {
    orderId: 'order-1',
    payerId: 'buyer-1',
    payeeId: 'seller-1',
    amount: 1000,
    currency: 'RWF',
    paymentMethod: 'PaymentMethod.mtnMomo',
    status: 'PaymentStatus.pending',
    transactionId: 'client-reference-1',
    externalTransactionId: null,
    phoneNumber: '0780000000',
    paymentDetails: null,
    createdAt: stamp(),
    completedAt: null,
    failureReason: null,
    webhookData: null,
  };

  await assertSucceeds(setDoc(doc(buyerDb, 'payments/payment-1'), validPayment));
  await assertFails(setDoc(doc(buyerDb, 'payments/wrong-amount'), {
    ...validPayment, amount: 1,
  }));
  await assertFails(setDoc(doc(buyerDb, 'payments/pretend-paid'), {
    ...validPayment, status: 'PaymentStatus.completed',
  }));
});

test('clients cannot change or delete payment records', async () => {
  await seed('payments/payment-1', {
    orderId: 'order-1', payerId: 'buyer-1', payeeId: 'seller-1',
    amount: 1000, currency: 'RWF', paymentMethod: 'PaymentMethod.mtnMomo',
    status: 'PaymentStatus.pending', createdAt: stamp(),
  });
  const buyerDb = testEnv.authenticatedContext('buyer-1', {
    email: 'buyer@example.com',
  }).firestore();

  await assertFails(updateDoc(doc(buyerDb, 'payments/payment-1'), {
    status: 'PaymentStatus.completed',
  }));
  await assertFails(deleteDoc(doc(buyerDb, 'payments/payment-1')));
});
