# 💰 Payment API Integration - Complete Setup Guide

## 🎯 Overview

This guide will help you integrate **real MTN MoMo and Airtel Money APIs** for accepting payments in your iTraceLink app.

**Status**: Foundation complete, ready for production credentials

---

## 📋 What's Already Implemented

### ✅ Complete Infrastructure:
- Payment service with MTN MoMo integration
- Payment service with Airtel Money integration
- Payment models
- Status checking
- Phone number validation
- Transaction reference generation
- Error handling framework

### 🔄 Current State:
- Sandbox/development mode ready
- Production credentials needed
- Webhook handling needs Firebase Functions

---

## 🏗️ Architecture

```
┌──────────────┐
│   Customer   │
│   (Farmer)   │
└──────┬───────┘
       │ Initiates Payment
       ▼
┌──────────────────┐
│  Flutter App     │
│  PaymentService  │
└──────┬───────────┘
       │
       ├──► MTN MoMo API
       │    (Collection)
       │
       └──► Airtel Money API
            (Payments)
       
       ▼
┌──────────────────┐
│   Callback/      │
│   Webhook        │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│    Firestore     │
│  Update Status   │
└──────────────────┘
```

---

## 🚀 Step 1: Get API Credentials

### **MTN MoMo API**

#### A. Register on MTN MoMo Developer Portal
1. Go to: https://momodeveloper.mtn.com/
2. Click "Sign Up"
3. Complete registration
4. Verify your email

#### B. Subscribe to Collections API
1. Login to portal
2. Go to "Products" → "Collections"
3. Click "Subscribe"
4. Get your **Primary Key** (API Key)

#### C. Create API User (Sandbox)
```bash
# Generate UUID for API User
UUID=$(uuidgen)

# Create API User
curl -X POST \
  https://sandbox.momodeveloper.mtn.com/v1_0/apiuser \
  -H 'Content-Type: application/json' \
  -H 'X-Reference-Id: YOUR_UUID' \
  -H 'Ocp-Apim-Subscription-Key: YOUR_PRIMARY_KEY' \
  -d '{
    "providerCallbackHost": "your-domain.com"
  }'

# Get API Secret
curl -X POST \
  https://sandbox.momodeveloper.mtn.com/v1_0/apiuser/YOUR_UUID/apikey \
  -H 'Ocp-Apim-Subscription-Key: YOUR_PRIMARY_KEY'
```

#### D. Save Credentials
- API Key (Subscription Key): `YOUR_PRIMARY_KEY`
- API User: `YOUR_UUID`
- API Secret: Response from apikey endpoint

---

### **Airtel Money API**

#### A. Register on Airtel Developer Portal
1. Go to: https://developers.airtel.africa/
2. Click "Sign Up"
3. Complete registration
4. Verify email

#### B. Get API Credentials
1. Login to portal
2. Go to "My Apps"
3. Create new app
4. Select "Payments" API
5. Get **Client ID** and **Client Secret**

#### C. Configure Callback URL
1. In app settings
2. Add webhook URL: `https://your-domain.com/api/payments/airtel/callback`
3. Save configuration

---

## 🔧 Step 2: Configure Your App

### A. Update `.env` File

Create `.env` in project root:

```env
# MTN MoMo Configuration
MTN_MOMO_API_KEY=your_primary_subscription_key_here
MTN_MOMO_API_SECRET=your_api_secret_here
MTN_MOMO_BASE_URL=https://sandbox.momodeveloper.mtn.com
MTN_MOMO_CALLBACK_URL=https://your-domain.com/api/payments/mtn/callback
MTN_COLLECTION_ACCOUNT=your_api_user_uuid_here

# Airtel Money Configuration
AIRTEL_API_KEY=your_client_id_here
AIRTEL_API_SECRET=your_client_secret_here
AIRTEL_BASE_URL=https://openapiuat.airtel.africa
AIRTEL_CALLBACK_URL=https://your-domain.com/api/payments/airtel/callback
AIRTEL_COLLECTION_ACCOUNT=your_merchant_id_here
```

### B. Initialize Payment Service

In your `main.dart`:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/payment_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize Payment Service
  PaymentService().initialize();
  
  runApp(MyApp());
}
```

---

## 💳 Step 3: Using the Payment Service

### **Example: Process Order Payment**

```dart
import 'package:itracelink/services/payment_service.dart';
import 'package:itracelink/models/payment_model.dart';

Future<void> processOrderPayment({
  required String orderId,
  required String buyerId,
  required String sellerId,
  required double amount,
  required String phoneNumber,
  required PaymentMethod paymentMethod,
}) async {
  final paymentService = PaymentService();
  
  try {
    // 1. Generate transaction reference
    final reference = paymentService.generateTransactionReference(orderId);
    
    // 2. Validate phone number
    if (!paymentService.isValidPhoneNumber(phoneNumber, paymentMethod)) {
      throw Exception('Invalid phone number for selected payment method');
    }
    
    // 3. Format phone number
    final formattedPhone = paymentService.formatPhoneNumber(phoneNumber);
    
    // 4. Create payment request
    final request = PaymentRequest(
      phoneNumber: formattedPhone,
      amount: amount,
      currency: 'RWF',
      reference: reference,
      description: 'Payment for Order #$orderId',
    );
    
    // 5. Create payment record in Firestore
    final paymentDoc = await FirebaseFirestore.instance
        .collection('payments')
        .add(PaymentModel(
          id: '',
          orderId: orderId,
          payerId: buyerId,
          payeeId: sellerId,
          amount: amount,
          currency: 'RWF',
          paymentMethod: paymentMethod,
          status: PaymentStatus.pending,
          phoneNumber: formattedPhone,
          transactionId: reference,
          createdAt: DateTime.now(),
        ).toMap());
    
    // 6. Process payment
    final response = await paymentService.processPayment(paymentMethod, request);
    
    if (response.success) {
      // 7. Update payment status to processing
      await paymentDoc.update({
        'status': PaymentStatus.processing.toString(),
        'externalTransactionId': response.transactionId,
      });
      
      // 8. Start status polling
      _pollPaymentStatus(paymentDoc.id, paymentMethod, response.transactionId!);
      
      return response.transactionId;
    } else {
      // Update payment as failed
      await paymentDoc.update({
        'status': PaymentStatus.failed.toString(),
        'failureReason': response.message,
      });
      
      throw Exception(response.message ?? 'Payment failed');
    }
  } catch (e) {
    print('Payment Error: $e');
    rethrow;
  }
}

// Poll payment status
Future<void> _pollPaymentStatus(
  String paymentId,
  PaymentMethod method,
  String transactionId,
) async {
  final paymentService = PaymentService();
  
  // Poll every 5 seconds for up to 2 minutes
  for (int i = 0; i < 24; i++) {
    await Future.delayed(const Duration(seconds: 5));
    
    final status = await paymentService.checkPaymentStatus(method, transactionId);
    
    if (status == PaymentStatus.completed) {
      await FirebaseFirestore.instance
          .collection('payments')
          .doc(paymentId)
          .update({
        'status': PaymentStatus.completed.toString(),
        'completedAt': Timestamp.now(),
      });
      break;
    } else if (status == PaymentStatus.failed) {
      await FirebaseFirestore.instance
          .collection('payments')
          .doc(paymentId)
          .update({
        'status': PaymentStatus.failed.toString(),
      });
      break;
    }
  }
}
```

---

## 🔄 Step 4: Webhook Setup (Optional but Recommended)

Webhooks provide real-time payment status updates instead of polling.

### **A. Create Firebase Cloud Functions**

```javascript
// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// MTN MoMo Webhook
exports.mtnMomoWebhook = functions.https.onRequest(async (req, res) => {
  try {
    const { referenceId, status, reason } = req.body;
    
    // Find payment by transaction ID
    const paymentSnapshot = await admin.firestore()
      .collection('payments')
      .where('externalTransactionId', '==', referenceId)
      .get();
    
    if (paymentSnapshot.empty) {
      return res.status(404).send('Payment not found');
    }
    
    const paymentDoc = paymentSnapshot.docs[0];
    
    // Update payment status
    const updateData = {
      status: status === 'SUCCESSFUL' ? 'PaymentStatus.completed' : 'PaymentStatus.failed',
      webhookData: JSON.stringify(req.body),
    };
    
    if (status === 'SUCCESSFUL') {
      updateData.completedAt = admin.firestore.FieldValue.serverTimestamp();
    } else if (status === 'FAILED') {
      updateData.failureReason = reason;
    }
    
    await paymentDoc.ref.update(updateData);
    
    res.status(200).send('Webhook processed');
  } catch (error) {
    console.error('MTN Webhook Error:', error);
    res.status(500).send('Internal error');
  }
});

// Airtel Money Webhook
exports.airtelMoneyWebhook = functions.https.onRequest(async (req, res) => {
  try {
    const { transaction } = req.body;
    const { id, status, message } = transaction;
    
    // Find payment
    const paymentSnapshot = await admin.firestore()
      .collection('payments')
      .where('externalTransactionId', '==', id)
      .get();
    
    if (paymentSnapshot.empty) {
      return res.status(404).send('Payment not found');
    }
    
    const paymentDoc = paymentSnapshot.docs[0];
    
    // Update status
    const updateData = {
      status: status === 'SUCCESS' ? 'PaymentStatus.completed' : 'PaymentStatus.failed',
      webhookData: JSON.stringify(req.body),
    };
    
    if (status === 'SUCCESS') {
      updateData.completedAt = admin.firestore.FieldValue.serverTimestamp();
    } else {
      updateData.failureReason = message;
    }
    
    await paymentDoc.ref.update(updateData);
    
    res.status(200).send('Webhook processed');
  } catch (error) {
    console.error('Airtel Webhook Error:', error);
    res.status(500).send('Internal error');
  }
});
```

### **B. Deploy Functions**

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Initialize functions
firebase init functions

# Deploy
firebase deploy --only functions
```

### **C. Update Webhook URLs in .env**

```env
MTN_MOMO_CALLBACK_URL=https://us-central1-your-project.cloudfunctions.net/mtnMomoWebhook
AIRTEL_CALLBACK_URL=https://us-central1-your-project.cloudfunctions.net/airtelMoneyWebhook
```

---

## 🧪 Step 5: Testing

### **Sandbox Testing (MTN MoMo)**

Use test phone numbers:
- **Success**: 46733123450
- **Failed**: 46733123451
- **Timeout**: 46733123452
- **Ongoing**: 46733123453

### **Sandbox Testing (Airtel Money)**

Contact Airtel support for test credentials and phone numbers.

### **Test Flow**:

```dart
// Test payment
final response = await PaymentService().processPayment(
  PaymentMethod.mtnMomo,
  PaymentRequest(
    phoneNumber: '46733123450', // Test number
    amount: 1000,
    currency: 'EUR', // Sandbox uses EUR
    reference: 'TEST_${DateTime.now().millisecondsSinceEpoch}',
    description: 'Test payment',
  ),
);

print('Payment initiated: ${response.success}');

// Check status after 10 seconds
await Future.delayed(Duration(seconds: 10));

final status = await PaymentService().checkPaymentStatus(
  PaymentMethod.mtnMomo,
  response.transactionId!,
);

print('Payment status
