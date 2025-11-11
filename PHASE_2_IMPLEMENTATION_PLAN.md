# Phase 2 Implementation Plan - iTraceLink

**Current Status:** 15% Complete
**Target:** 100% Complete
**Estimated Time:** 2-3 weeks
**Priority:** High (Required for full production launch)

---

## Feature Breakdown

### 1. Order Management Workflow (40% → 100%) - Priority: HIGH

**Current State:**
- ✅ Order data model exists
- ✅ Basic order creation UI exists
- ❌ Order acceptance workflow missing
- ❌ Order fulfillment tracking missing
- ❌ Order status updates incomplete

**Tasks to Complete:**

#### Task 1.1: Order Acceptance/Rejection (2 days)
```dart
// lib/screens/orders/pending_orders_screen.dart
// Allow sellers to accept or reject incoming orders

class PendingOrdersScreen extends StatelessWidget {
  // Display pending orders for the seller
  // Add "Accept" and "Reject" buttons
  // Update order status in Firestore
  // Send notification to buyer
}
```

**Implementation Steps:**
1. Create PendingOrdersScreen for sellers
2. Add accept/reject actions
3. Update Firestore with new status
4. Trigger notifications (placeholder for now)

#### Task 1.2: Order Fulfillment Tracking (3 days)
```dart
// lib/screens/orders/order_details_screen.dart
// Track order progress through stages

enum OrderStatus {
  pending,
  accepted,
  preparing,
  ready_for_pickup,
  in_transit,
  delivered,
  completed,
  cancelled,
  rejected
}

// Add status update buttons for sellers
// Add delivery confirmation for buyers
// Add estimated delivery date tracking
```

**Implementation Steps:**
1. Expand OrderStatus enum
2. Create order timeline widget
3. Add status update functionality
4. Add delivery confirmation
5. Update order history

#### Task 1.3: Order History and Tracking (1 day)
```dart
// lib/screens/orders/order_history_screen.dart
// View past orders with filters

- Filter by status (pending, completed, cancelled)
- Filter by date range
- Search by batch number or buyer/seller name
- Export order history to CSV
```

**Estimated Time:** 6 days

---

### 2. Payment Integration (0% → 100%) - Priority: HIGH

**Current State:**
- ❌ No payment integration
- ❌ Payment data model incomplete
- ❌ Payment verification missing

**Tasks to Complete:**

#### Task 2.1: MTN Mobile Money Integration (4 days)

**API Documentation:** https://momodeveloper.mtn.com/

**Implementation Steps:**

1. **Set up MTN MoMo API credentials:**
```bash
# Environment variables (.env)
MTN_MOMO_API_KEY=your_api_key
MTN_MOMO_SUBSCRIPTION_KEY=your_subscription_key
MTN_MOMO_API_BASE_URL=https://sandbox.momodeveloper.mtn.com
MTN_MOMO_CALLBACK_URL=https://your-domain.com/api/momo-callback
```

2. **Create payment service:**
```dart
// lib/services/mtn_momo_service.dart

class MtnMomoService {
  // Request to Pay API
  Future<String> requestToPay({
    required String phoneNumber,
    required double amount,
    required String currency,
    required String externalId,
    required String payerMessage,
    required String payeeNote,
  }) async {
    // Call MTN MoMo API
    // Return transaction reference
  }

  // Check payment status
  Future<PaymentStatus> getTransactionStatus(String referenceId) async {
    // Query MTN MoMo API
    // Return SUCCESSFUL, FAILED, or PENDING
  }

  // Request account balance
  Future<double> getAccountBalance() async {
    // Query account balance
  }
}
```

3. **Create payment UI:**
```dart
// lib/screens/payment/mtn_payment_screen.dart

class MtnPaymentScreen extends StatefulWidget {
  final OrderModel order;

  // Display order summary
  // Input phone number for payment
  // Initiate payment
  // Show payment status (loading, success, failed)
  // Redirect on success
}
```

4. **Handle payment callbacks:**
```dart
// Webhook endpoint to receive payment confirmation
// Update order payment status in Firestore
// Send notification to seller
```

**Estimated Time:** 4 days

#### Task 2.2: Airtel Money Integration (3 days)

**API Documentation:** https://developers.airtel.africa/

**Implementation:**
- Similar to MTN MoMo integration
- Use Airtel Money API
- Create AirtelMoneyService class
- Create Airtel payment UI

**Estimated Time:** 3 days

#### Task 2.3: Payment Method Selection (1 day)
```dart
// lib/screens/payment/payment_method_screen.dart

class PaymentMethodScreen extends StatelessWidget {
  // Display available payment methods:
  // - MTN Mobile Money
  // - Airtel Money
  // - Cash on Delivery (for pilot)

  // Navigate to selected payment method screen
}
```

**Estimated Time:** 1 day

**Total Payment Integration Time:** 8 days

---

### 3. QR Code System (0% → 100%) - Priority: MEDIUM

**Current State:**
- ❌ QR code generation not implemented
- ❌ QR code scanning not implemented
- ❌ Consumer verification missing

**Tasks to Complete:**

#### Task 3.1: QR Code Generation (2 days)

**Dependencies:**
```yaml
# pubspec.yaml
dependencies:
  qr_flutter: ^4.1.0
```

**Implementation:**
```dart
// lib/services/qr_code_service.dart

class QrCodeService {
  // Generate QR code for batch
  Widget generateBatchQrCode(BatchModel batch) {
    // Encode batch information
    final qrData = jsonEncode({
      'batchId': batch.id,
      'farmerId': batch.farmerId,
      'batchNumber': batch.batchNumber,
      'verifyUrl': 'https://itracelink.app/verify/${batch.id}',
      'timestamp': DateTime.now().toIso8601String(),
    });

    return QrImageView(
      data: qrData,
      version: QrVersions.auto,
      size: 200.0,
    );
  }
}

// Add QR code to batch details screen
// Allow farmers to print/share QR code
```

**Estimated Time:** 2 days

#### Task 3.2: QR Code Scanning (2 days)

**Dependencies:**
```yaml
# pubspec.yaml
dependencies:
  mobile_scanner: ^3.5.0
```

**Implementation:**
```dart
// lib/screens/qr/qr_scanner_screen.dart

class QrScannerScreen extends StatefulWidget {
  // Open camera for QR scanning
  // Decode QR data
  // Fetch batch information from Firestore
  // Display traceability chain
}

// Add "Scan QR Code" button to consumer/institution dashboard
```

**Estimated Time:** 2 days

#### Task 3.3: Consumer Verification (1 day)
```dart
// lib/screens/consumer/verify_batch_screen.dart

class VerifyBatchScreen extends StatelessWidget {
  final String batchId;

  // Display:
  // - Batch authenticity status
  // - Complete traceability chain
  // - Quality certifications
  // - Iron content verification
  // - Farmer information
}
```

**Estimated Time:** 1 day

**Total QR Code Time:** 5 days

---

### 4. Notification System (30% → 100%) - Priority: MEDIUM

**Current State:**
- ✅ Notification data model exists
- ✅ Firebase Cloud Messaging configured
- ❌ SMS notifications not implemented
- ❌ Email notifications not implemented
- ❌ Push notification triggers missing

**Tasks to Complete:**

#### Task 4.1: SMS Notifications via Africa's Talking (2 days)

**API Documentation:** https://developers.africastalking.com/

**Implementation:**
```dart
// lib/services/sms_service.dart

class SmsService {
  final String apiKey = dotenv.env['AFRICAS_TALKING_API_KEY']!;
  final String username = dotenv.env['AFRICAS_TALKING_USERNAME']!;

  Future<bool> sendOrderNotification({
    required String phoneNumber,
    required String message,
  }) async {
    final url = 'https://api.africastalking.com/version1/messaging';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'apiKey': apiKey,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'username': username,
          'to': phoneNumber,
          'message': message,
        },
      );

      return response.statusCode == 201;
    } catch (e) {
      debugPrint('SMS Error: $e');
      return false;
    }
  }
}

// SMS templates for different events:
// - Order placed
// - Order accepted
// - Order delivered
// - Payment received
```

**Trigger Points:**
1. Order created → Notify seller
2. Order accepted → Notify buyer
3. Order status updated → Notify both parties
4. Payment received → Notify seller

**Estimated Time:** 2 days

#### Task 4.2: Email Notifications via Sendgrid (2 days)

**Implementation:**
```dart
// lib/services/email_service.dart - Enhance existing

class EmailService {
  // Add email templates
  Future<void> sendOrderConfirmationEmail({
    required String to,
    required OrderModel order,
  }) async {
    final template = '''
    <html>
      <body>
        <h2>Order Confirmation</h2>
        <p>Order #${order.id} has been placed.</p>
        <p>Quantity: ${order.quantity} kg</p>
        <p>Total: ${order.totalAmount} RWF</p>
        <a href="https://itracelink.app/orders/${order.id}">View Order</a>
      </body>
    </html>
    ''';

    await sendEmail(
      to: to,
      subject: 'Order Confirmation - iTraceLink',
      htmlContent: template,
    );
  }
}
```

**Estimated Time:** 2 days

#### Task 4.3: Push Notifications (1 day)

**Implementation:**
```dart
// lib/services/notification_service.dart - Enhance existing

class NotificationService {
  // Send push notification via FCM
  Future<void> sendPushNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // Get user FCM token from Firestore
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    final fcmToken = userDoc.data()?['fcmToken'];

    if (fcmToken != null) {
      // Send via Firebase Admin SDK (requires backend function)
      // OR use Firebase Functions to send
    }
  }
}

// Add FCM token registration on login
// Store token in Firestore users collection
```

**Estimated Time:** 1 day

#### Task 4.4: Notification Preferences (1 day)
```dart
// lib/screens/settings/notification_settings_screen.dart

class NotificationSettingsScreen extends StatefulWidget {
  // Allow users to configure:
  // - Enable/disable push notifications
  // - Enable/disable SMS notifications
  // - Enable/disable email notifications
  // - Notification frequency
}
```

**Estimated Time:** 1 day

**Total Notification Time:** 6 days

---

### 5. Additional Features (Optional but Valuable)

#### Task 5.1: Google Maps Location Picker (2 days)

**Dependencies:**
```yaml
# pubspec.yaml
dependencies:
  google_maps_flutter: ^2.5.0
  geolocator: ^10.1.0
```

**Implementation:**
```dart
// lib/screens/location/map_picker_screen.dart

class MapPickerScreen extends StatefulWidget {
  // Display Google Maps
  // Allow user to pick location via marker
  // Reverse geocode to get address
  // Return coordinates and address
}

// Use in profile forms for precise location
```

**Estimated Time:** 2 days

#### Task 5.2: In-App Chat (3 days)

```dart
// lib/screens/chat/chat_screen.dart

// Allow direct messaging between:
// - Farmers ↔ Aggregators
// - Aggregators ↔ Institutions
// - Support chat with admin

// Use Firestore real-time listeners for messages
```

**Estimated Time:** 3 days

---

## Implementation Schedule (15 working days)

### Week 1: Order Management & Payment (Days 1-8)
**Days 1-3:** Order acceptance, rejection, and fulfillment tracking
**Days 4-6:** MTN Mobile Money integration
**Days 7-8:** Airtel Money integration

### Week 2: QR Codes & Notifications (Days 9-15)
**Days 9-11:** QR code generation and scanning
**Days 12-13:** SMS notifications (Africa's Talking)
**Days 14:** Email notifications (Sendgrid)
**Day 15:** Push notifications & preferences

### Week 3 (Optional): Polish & Additional Features
**Days 16-17:** Google Maps integration
**Days 18-20:** In-app chat
**Days 21:** Testing and bug fixes

---

## Testing Strategy for Phase 2

### Payment Testing
- Use MTN/Airtel sandbox environments
- Test with small amounts (10-100 RWF)
- Verify payment status updates
- Test payment failure scenarios

### QR Code Testing
- Generate QR codes for test batches
- Scan with different devices
- Verify data integrity
- Test invalid QR codes

### Notification Testing
- Send test SMS (monitor costs!)
- Send test emails
- Verify notification triggers
- Test notification preferences

---

## Cost Estimates

### Development Costs
- Developer time: 15 days × $50/day = $750

### Operational Costs (Monthly)
- **SMS:** $0.05/SMS × 1000 SMS = $50/month
- **Email:** Sendgrid free tier (100 emails/day)
- **Firebase:** Firestore free tier sufficient for pilot
- **MTN/Airtel:** Transaction fees (~2-3%)

**Total Monthly Operating Cost:** ~$50 + transaction fees

---

## Dependencies and Prerequisites

### API Accounts Needed
1. ✅ Firebase (already configured)
2. ⏳ MTN Mobile Money Developer Account
3. ⏳ Airtel Money Developer Account
4. ⏳ Africa's Talking Account
5. ⏳ Sendgrid Account (already have)
6. ⏳ Google Maps API Key

### Documentation Required
- MTN MoMo API documentation
- Airtel Money API documentation
- Africa's Talking API documentation
- Google Maps API documentation

---

## Success Metrics for Phase 2

- [ ] Users can place orders through the app (no phone calls)
- [ ] Payments processed via mobile money (>80% success rate)
- [ ] Users receive notifications for all order events
- [ ] QR codes scannable and display correct information
- [ ] End-to-end order workflow takes <5 minutes
- [ ] Payment confirmation within 2 minutes
- [ ] SMS delivery within 30 seconds

---

## Risks and Mitigation

**Risk 1: Payment API Integration Issues**
- Mitigation: Start with sandbox testing, have fallback to cash on delivery

**Risk 2: SMS Costs Higher Than Expected**
- Mitigation: Implement notification preferences, use push notifications primarily

**Risk 3: QR Code Scanning Issues on Low-End Devices**
- Mitigation: Provide manual batch ID entry option

**Risk 4: Network Connectivity for Payments**
- Mitigation: Implement payment status polling, offline payment queue

---

## Post-Phase 2 Roadmap

**Phase 3: Analytics & Reporting (1 week)**
- Sales reports for farmers
- Purchase reports for institutions
- Supply chain analytics
- Predictive inventory management

**Phase 4: Advanced Features (2 weeks)**
- Contract farming
- Price discovery mechanism
- Credit scoring for farmers
- Logistics integration

---

**Last Updated:** 2025-11-11
**Status:** Ready to Begin
**Next Step:** Start with Order Management (Week 1, Days 1-3)
