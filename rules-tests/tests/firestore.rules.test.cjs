const { readFileSync } = require('node:fs');
const { before, beforeEach, after, test } = require('node:test');
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


test('order lifecycle allows only the designated buyer and seller transitions', async () => {
  await seedOrder('pending');
  const sellerDb = testEnv.authenticatedContext('seller-1', {
    email: 'seller@example.com',
  }).firestore();
  const buyerDb = testEnv.authenticatedContext('buyer-1', {
    email: 'buyer@example.com',
  }).firestore();

  await assertSucceeds(updateDoc(doc(sellerDb, 'orders/order-1'), {
    status: 'accepted', updatedAt: stamp(), acceptedAt: stamp(),
  }));
  await assertSucceeds(updateDoc(doc(sellerDb, 'orders/order-1'), {
    status: 'preparing', updatedAt: stamp(), preparingAt: stamp(),
  }));
  await assertSucceeds(updateDoc(doc(sellerDb, 'orders/order-1'), {
    status: 'shipped', updatedAt: stamp(), shippedAt: stamp(),
  }));
  await assertSucceeds(updateDoc(doc(buyerDb, 'orders/order-1'), {
    status: 'collected', updatedAt: stamp(), collectedAt: stamp(),
  }));
  await assertSucceeds(updateDoc(doc(buyerDb, 'orders/order-1'), {
    status: 'in_transit', updatedAt: stamp(), inTransitAt: stamp(),
  }));
  await assertSucceeds(updateDoc(doc(buyerDb, 'orders/order-1'), {
    status: 'delivered', updatedAt: stamp(), deliveredAt: stamp(),
  }));
  await assertSucceeds(updateDoc(doc(sellerDb, 'orders/order-1'), {
    status: 'completed', updatedAt: stamp(), completedAt: stamp(),
  }));
  await assertFails(updateDoc(doc(sellerDb, 'orders/order-1'), {
    status: 'accepted', updatedAt: stamp(), acceptedAt: stamp(),
  }));
});

test('seller rejection and buyer cancellation are permitted only from pending', async () => {
  const sellerDb = testEnv.authenticatedContext('seller-1', {
    email: 'seller@example.com',
  }).firestore();
  const buyerDb = testEnv.authenticatedContext('buyer-1', {
    email: 'buyer@example.com',
  }).firestore();

  await seedOrder('pending');
  await assertSucceeds(updateDoc(doc(sellerDb, 'orders/order-1'), {
    status: 'rejected', updatedAt: stamp(), rejectedAt: stamp(),
    rejectionReason: 'Out of stock',
  }));

  await seedOrder('pending');
  await assertSucceeds(updateDoc(doc(buyerDb, 'orders/order-1'), {
    status: 'cancelled', updatedAt: stamp(),
  }));

  await seedOrder('accepted');
  await assertFails(updateDoc(doc(buyerDb, 'orders/order-1'), {
    status: 'cancelled', updatedAt: stamp(),
  }));
});

test('notifications cannot be created for another user or rewritten after creation', async () => {
  const ownerDb = testEnv.authenticatedContext('user-1', {
    email: 'user@example.com',
  }).firestore();
  const otherDb = testEnv.authenticatedContext('user-2', {
    email: 'other@example.com',
  }).firestore();

  const notification = {
    userId: 'user-1',
    title: 'Order update',
    body: 'Your order was updated',
    type: 'order',
    relatedId: 'order-1',
    createdAt: stamp(),
    isRead: false,
  };

  await assertSucceeds(setDoc(doc(ownerDb, 'notifications/own'), notification));
  await assertFails(setDoc(doc(otherDb, 'notifications/spoofed'), notification));
  await assertSucceeds(updateDoc(doc(ownerDb, 'notifications/own'), { isRead: true }));
  await assertFails(updateDoc(doc(ownerDb, 'notifications/own'), {
    title: 'Fake payment received',
  }));
  await assertFails(updateDoc(doc(ownerDb, 'notifications/own'), {
    userId: 'user-2', isRead: true,
  }));
  await assertFails(updateDoc(doc(ownerDb, 'notifications/own'), { isRead: false }));
});


test('business profile creation cannot claim another account or self-verify', async () => {
  await seed('users/user-1', {
    userType: 'cooperative',
    name: 'Cooperative Owner',
    email: 'owner@example.com',
    isVerified: false,
  });

  const ownerDb = testEnv.authenticatedContext('user-1', {
    email: 'owner@example.com',
  }).firestore();

  await assertSucceeds(setDoc(doc(ownerDb, 'cooperatives/own-coop'), {
    userId: 'user-1',
    cooperativeName: 'Own Cooperative',
    isVerified: false,
    isActive: true,
  }));

  await assertFails(setDoc(doc(ownerDb, 'cooperatives/claimed-coop'), {
    userId: 'user-2',
    cooperativeName: 'Claimed Cooperative',
    isVerified: false,
    isActive: true,
  }));

  await assertFails(updateDoc(doc(ownerDb, 'cooperatives/own-coop'), {
    isVerified: true,
  }));
  await assertFails(updateDoc(doc(ownerDb, 'cooperatives/own-coop'), {
    userId: 'user-2',
  }));
});


test('seed batches enforce producer ownership and prevent stock increases or certificate edits', async () => {
  await seed('users/producer-1', { userType: 'seed_producer', email: 'producer@example.com' });
  const producerDb = testEnv.authenticatedContext('producer-1', {
    email: 'producer@example.com',
  }).firestore();
  const batch = {
    producerId: 'producer-1', batchNumber: 'SB-1', variety: 'Iron bean',
    quantity: 100, qualityGrade: 'Grade A',
    productionDate: stamp(), expiryDate: stamp(),
    certificationNumber: 'CERT-1', status: 'active', createdAt: stamp(),
    ironContent: 80,
  };
  await assertSucceeds(setDoc(doc(producerDb, 'seed_batches/batch-1'), batch));
  await assertFails(setDoc(doc(producerDb, 'seed_batches/forged'), {
    ...batch, producerId: 'someone-else',
  }));
  await assertSucceeds(updateDoc(doc(producerDb, 'seed_batches/batch-1'), { quantity: 80 }));
  await assertFails(updateDoc(doc(producerDb, 'seed_batches/batch-1'), { quantity: 200 }));
  await assertFails(updateDoc(doc(producerDb, 'seed_batches/batch-1'), {
    certificationNumber: 'FAKE-CERT',
  }));
});

test('seed distributions cannot be attributed to another producer or rewrite recipients', async () => {
  await seed('users/producer-1', { userType: 'seed_producer' });
  const producerDb = testEnv.authenticatedContext('producer-1').firestore();
  const distribution = {
    seedProducerId: 'producer-1', seedVariety: 'Iron bean', quantity: 50,
    recipientId: 'farmer-1', recipientName: 'Farmer', recipientType: 'farmer',
    distributionDate: stamp(), distributionMethod: 'direct',
    certificationNumber: 'CERT-1', ironContent: 80, quality: 'certified',
    status: 'distributed', followUpRequired: false,
  };
  await assertSucceeds(setDoc(doc(producerDb, 'seed_distributions/dist-1'), distribution));
  await assertFails(setDoc(doc(producerDb, 'seed_distributions/forged'), {
    ...distribution, seedProducerId: 'someone-else',
  }));
  await assertSucceeds(updateDoc(doc(producerDb, 'seed_distributions/dist-1'), {
    status: 'planted',
  }));
  await assertFails(updateDoc(doc(producerDb, 'seed_distributions/dist-1'), {
    recipientId: 'different-farmer',
  }));
});

test('dealer sales enforce ownership and totals and cannot be rewritten', async () => {
  await seed('users/dealer-1', { userType: 'agro_dealer' });
  const dealerDb = testEnv.authenticatedContext('dealer-1').firestore();
  const sale = {
    agroDealerId: 'dealer-1', seedVariety: 'Iron bean', quantity: 10,
    pricePerKg: 100, totalAmount: 1000, customerId: 'customer-1',
    customerName: 'Customer', customerType: 'farmer', saleDate: stamp(),
    paymentStatus: 'pending', paymentMethod: 'cash',
  };
  await assertSucceeds(setDoc(doc(dealerDb, 'agro_dealer_sales/sale-1'), sale));
  await assertFails(setDoc(doc(dealerDb, 'agro_dealer_sales/forged'), {
    ...sale, agroDealerId: 'other-dealer',
  }));
  await assertFails(setDoc(doc(dealerDb, 'agro_dealer_sales/wrong-total'), {
    ...sale, totalAmount: 1,
  }));
  await assertFails(updateDoc(doc(dealerDb, 'agro_dealer_sales/sale-1'), {
    paymentStatus: 'completed',
  }));
});

test('transactions use the model schema, validate totals, and are immutable', async () => {
  const buyerDb = testEnv.authenticatedContext('buyer-1').firestore();
  const transaction = {
    type: 'purchase', sellerId: 'seller-1', sellerName: 'Seller',
    buyerId: 'buyer-1', buyerName: 'Buyer', batchId: 'batch-1',
    batchNumber: 'B-1', quantity: 10, pricePerKg: 100, totalAmount: 1000,
    transactionDate: stamp(), paymentStatus: 'pending', paymentMethod: 'cash',
    receiptNumber: null, location: {}, status: 'pending', notes: null,
  };
  await assertSucceeds(setDoc(doc(buyerDb, 'transactions/txn-1'), transaction));
  await assertFails(setDoc(doc(buyerDb, 'transactions/forged-total'), {
    ...transaction, totalAmount: 1,
  }));
  await assertFails(updateDoc(doc(buyerDb, 'transactions/txn-1'), {
    paymentStatus: 'completed',
  }));
});


test('batch creation binds ownership and batch updates cannot change ownership or protected fields', async () => {
  await seed('users/farmer-1', { userType: 'farmer', email: 'farmer@example.com' });
  const farmerDb = testEnv.authenticatedContext('farmer-1', {
    email: 'farmer@example.com',
  }).firestore();
  const batch = {
    farmerId: 'farmer-1',
    cooperativeName: 'Farmer One',
    batchNumber: 'BATCH-001',
    beanVariety: 'Iron bean',
    quantity: 100,
    status: 'growing',
    registrationDate: stamp(),
    harvestDate: null,
    plantingDate: stamp(),
    landSize: 0.5,
    seedSource: null,
    seedBatchNumber: null,
    seedBatchId: null,
    agroDealerId: null,
    quality: 'not_graded',
    pricePerKg: null,
    availableForSale: false,
    storageLocation: null,
    photos: [],
    ironContent: 80,
    notes: null,
    location: null,
  };

  await assertSucceeds(setDoc(doc(farmerDb, 'batches/batch-1'), batch));
  await assertFails(setDoc(doc(farmerDb, 'batches/forged'), {
    ...batch, farmerId: 'someone-else',
  }));
  await assertFails(updateDoc(doc(farmerDb, 'batches/batch-1'), {
    farmerId: 'someone-else',
  }));
  await assertFails(updateDoc(doc(farmerDb, 'batches/batch-1'), {
    ironContent: 999,
  }));
  await assertSucceeds(updateDoc(doc(farmerDb, 'batches/batch-1'), {
    status: 'available', availableForSale: true,
  }));
  await assertFails(deleteDoc(doc(farmerDb, 'batches/batch-1')));
});

test('aggregator inventory must reference a real batch and preserve stock limits and provenance', async () => {
  await seed('users/trader-1', { userType: 'aggregator', email: 'trader@example.com' });
  await seed('batches/batch-1', {
    farmerId: 'farmer-1', batchNumber: 'B-1', beanVariety: 'Iron bean',
    quantity: 100, status: 'available', registrationDate: stamp(),
    availableForSale: true, ironContent: 80,
  });
  const traderDb = testEnv.authenticatedContext('trader-1', {
    email: 'trader@example.com',
  }).firestore();
  const inventory = {
    traderId: 'trader-1',
    batchId: 'batch-1',
    batchNumber: 'B-1',
    beanVariety: 'Iron bean',
    quantityAvailable: 10,
    quantityPurchased: 10,
    quantitySold: 0,
    purchasePricePerKg: 100,
    sellingPricePerKg: null,
    purchaseDate: stamp(),
    supplierId: 'farmer-1',
    supplierName: 'Farmer One',
    storageLocation: 'Store A',
    status: 'in_stock',
    quality: 'A',
    expiryDate: null,
    ironContent: 80,
    notes: null,
  };

  await assertSucceeds(setDoc(doc(traderDb, 'inventory/inv-1'), inventory));
  await assertFails(setDoc(doc(traderDb, 'inventory/forged-owner'), {
    ...inventory, traderId: 'another-trader',
  }));
  await assertFails(setDoc(doc(traderDb, 'inventory/forged-supplier'), {
    ...inventory, supplierId: 'someone-else',
  }));
  await assertFails(setDoc(doc(traderDb, 'inventory/no-batch'), {
    ...inventory, batchId: 'missing-batch',
  }));
  await assertSucceeds(updateDoc(doc(traderDb, 'inventory/inv-1'), {
    quantityAvailable: 7, quantitySold: 3,
  }));
  await assertFails(updateDoc(doc(traderDb, 'inventory/inv-1'), {
    quantityPurchased: 100,
  }));
  await assertFails(updateDoc(doc(traderDb, 'inventory/inv-1'), {
    quantityAvailable: 9, quantitySold: 3,
  }));
});

test('agro-dealer inventory validates owner and stock values', async () => {
  await seed('users/dealer-1', { userType: 'agro_dealer', email: 'dealer@example.com' });
  const dealerDb = testEnv.authenticatedContext('dealer-1', {
    email: 'dealer@example.com',
  }).firestore();
  const item = {
    agroDealerId: 'dealer-1',
    seedVariety: 'Iron bean',
    quantity: 25,
    pricePerKg: 1000,
    quality: 'certified',
    ironContent: 80,
    addedDate: stamp(),
    status: 'in_stock',
  };

  await assertSucceeds(setDoc(doc(dealerDb, 'agro_dealer_inventory/item-1'), item));
  await assertFails(setDoc(doc(dealerDb, 'agro_dealer_inventory/forged'), {
    ...item, agroDealerId: 'someone-else',
  }));
  await assertFails(setDoc(doc(dealerDb, 'agro_dealer_inventory/negative'), {
    ...item, quantity: -1,
  }));
  await assertSucceeds(updateDoc(doc(dealerDb, 'agro_dealer_inventory/item-1'), {
    quantity: 20, lastUpdated: stamp(),
  }));
  await assertFails(updateDoc(doc(dealerDb, 'agro_dealer_inventory/item-1'), {
    certificationNumber: 'FAKE-CERT',
  }));
  await assertFails(deleteDoc(doc(dealerDb, 'agro_dealer_inventory/item-1')));
});

test('certification applicants cannot approve their own submissions', async () => {
  const producerDb = testEnv.authenticatedContext('producer-1').firestore();
  const certification = {
    producerId: 'producer-1', batchId: 'batch-1',
    type: 'CertificationType.ironContent',
    status: 'CertificationStatus.pending',
    certificateNumber: 'CERT-1', issuingAuthority: 'Lab',
    issueDate: stamp(), expiryDate: stamp(), testResults: {},
    documentUrls: [], rejectionReason: null, notes: null,
    createdAt: stamp(), reviewedAt: null, reviewedBy: null,
  };
  await assertSucceeds(setDoc(doc(producerDb, 'certifications/cert-1'), certification));
  await assertFails(updateDoc(doc(producerDb, 'certifications/cert-1'), {
    status: 'CertificationStatus.approved',
  }));
});

test('consumer scans cannot claim a product is verified and purchase records are private', async () => {
  const consumerDb = testEnv.authenticatedContext('consumer-1').firestore();
  const otherDb = testEnv.authenticatedContext('consumer-2').firestore();
  const purchase = {
    consumerId: 'consumer-1', batchId: 'batch-1', sellerId: 'seller-1',
    sellerName: 'Seller', sellerType: 'farmer', scanDate: stamp(),
    wasVerified: false, rating: null, review: null, photos: [],
    reportedFraud: false, fraudDetails: null,
  };
  await assertSucceeds(setDoc(doc(consumerDb, 'consumer_purchases/scan-1'), purchase));
  await assertFails(setDoc(doc(consumerDb, 'consumer_purchases/forged'), {
    ...purchase, wasVerified: true,
  }));
  await assertFails(getDoc(doc(otherDb, 'consumer_purchases/scan-1')));
  await assertSucceeds(updateDoc(doc(consumerDb, 'consumer_purchases/scan-1'), {
    rating: 5, review: 'Good quality',
  }));
});


test('business profile owners cannot self-verify at creation or through status metadata', async () => {
  await seed('users/user-1', {
    userType: 'cooperative', email: 'owner@example.com', isVerified: false,
  });
  const ownerDb = testEnv.authenticatedContext('user-1', {
    email: 'owner@example.com',
  }).firestore();

  await assertFails(setDoc(doc(ownerDb, 'cooperatives/falsely-verified'), {
    userId: 'user-1', cooperativeName: 'Fake verified cooperative',
    isVerified: true, isActive: true,
  }));
  await assertSucceeds(setDoc(doc(ownerDb, 'cooperatives/pending'), {
    userId: 'user-1', cooperativeName: 'Pending cooperative',
    isVerified: false, isActive: true,
  }));
  await assertFails(updateDoc(doc(ownerDb, 'cooperatives/pending'), {
    status: 'active',
  }));
  await assertFails(updateDoc(doc(ownerDb, 'cooperatives/pending'), {
    verifiedAt: stamp(),
  }));
});


test('only an active admin can verify a business profile', async () => {
  await seed('cooperatives/coop-1', {
    userId: 'owner-1', cooperativeName: 'Pending coop',
    isVerified: false, isActive: true, status: 'pending',
  });
  await seed('admins/admin@example.com', { isActive: true });
  const ownerDb = testEnv.authenticatedContext('owner-1', {
    email: 'owner@example.com',
  }).firestore();
  const adminDb = testEnv.authenticatedContext('admin-1', {
    email: 'admin@example.com',
  }).firestore();

  await assertFails(updateDoc(doc(ownerDb, 'cooperatives/coop-1'), {
    isVerified: true, status: 'active',
  }));
  await assertSucceeds(updateDoc(doc(adminDb, 'cooperatives/coop-1'), {
    isVerified: true, status: 'active', verifiedAt: stamp(),
  }));
});
