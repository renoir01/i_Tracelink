# iTraceLink Payment Integration

## Overview

iTraceLink now includes comprehensive mobile money payment integration for Rwanda, supporting both MTN MoMo and Airtel Money. This allows aggregators and other buyers to make secure payments for agricultural products through their mobile money accounts.

## Features

- ✅ **Dual Provider Support**: MTN MoMo and Airtel Money
- ✅ **Secure Payment Processing**: Encrypted transactions with provider APIs
- ✅ **Real-time Status Updates**: Live payment confirmation
- ✅ **Payment History**: Complete transaction tracking
- ✅ **Webhook Integration**: Automatic payment status updates
- ✅ **Phone Number Validation**: Rwanda-specific number validation
- ✅ **Multiple Currencies**: Support for RWF and EUR (sandbox)

## Supported Payment Methods

### MTN MoMo
- **Provider**: MTN Rwanda
- **Supported Numbers**: 078*, 079*, 072*
- **Environment**: Sandbox (development) & Production
- **Currency**: EUR (sandbox), RWF (production)

### Airtel Money
- **Provider**: Airtel Rwanda
- **Supported Numbers**: 073*, 078*, 079*
- **Environment**: Sandbox (development) & Production
- **Currency**: RWF

## Setup Instructions

### 1. Environment Configuration

Copy `.env.example` to `.env` and configure the following variables:

```bash
# MTN MoMo Configuration
MTN_MOMO_API_KEY=your_mtn_api_key
MTN_MOMO_API_SECRET=your_mtn_api_secret
MTN_MOMO_BASE_URL=https://sandbox.momodeveloper.mtn.com
MTN_MOMO_CALLBACK_URL=https://your-domain.com/api/payments/mtn/callback
MTN_COLLECTION_ACCOUNT=your_collection_account

# Airtel Money Configuration
AIRTEL_API_KEY=your_airtel_api_key
AIRTEL_API_SECRET=your_airtel_api_secret
AIRTEL_BASE_URL=https://openapiuat.airtel.africa
AIRTEL_CALLBACK_URL=https://your-domain.com/api/payments/airtel/callback
AIRTEL_COLLECTION_ACCOUNT=your_collection_account
```

### 2. API Registration

#### MTN MoMo Setup:
1. Visit [MTN Developer Portal](https://momodeveloper.mtn.com/)
2. Create a developer account
3. Register your application
4. Get API Key and Secret
5. Configure sandbox environment
6. Set up webhook endpoints

#### Airtel Money Setup:
1. Visit [Airtel Developer Portal](https://openapiuat.airtel.africa/)
2. Register as a developer
3. Create an application
4. Obtain API credentials
5. Configure webhook URLs

### 3. Webhook Configuration

Set up webhook endpoints on your server to handle payment confirmations:

#### MTN MoMo Webhook:
```
POST /api/payments/mtn/callback
Headers: X-Reference-Id, Ocp-Apim-Subscription-Key
Body: Payment confirmation data
```

#### Airtel Money Webhook:
```
POST /api/payments/airtel/callback
Headers: Authorization
Body: Transaction status data
```

## User Flow

### For Buyers (Aggregators):
1. **Order Acceptance**: Receive and accept order from farmer
2. **Payment Initiation**: Click "Pay Now" on pending payment
3. **Method Selection**: Choose MTN MoMo or Airtel Money
4. **Phone Entry**: Enter mobile money phone number
5. **Terms Agreement**: Accept payment terms
6. **SMS Confirmation**: Receive payment prompt on phone
7. **Approval**: Confirm payment via mobile money app
8. **Completion**: Payment processed and order marked as paid

### For Sellers:
- Receive payment notifications
- View payment history
- Track payment status
- Automatic order status updates

## Technical Implementation

### Core Components

#### PaymentService (`lib/services/payment_service.dart`)
- Central payment processing service
- API integrations for both providers
- Phone number validation
- Transaction reference generation
- Status checking and webhooks

#### PaymentModel (`lib/models/payment_model.dart`)
- Payment data structure
- Status tracking
- Transaction details
- Provider-specific information

#### PaymentScreen (`lib/screens/payment_screen.dart`)
- User interface for payment initiation
- Method selection and phone entry
- Terms and conditions
- Form validation

#### PaymentProcessingScreen (`lib/screens/payment_processing_screen.dart`)
- Real-time payment status monitoring
- User feedback and guidance
- Success/failure handling
- Timeout management

### Database Structure

```json
// payments collection
{
  "id": "payment_id",
  "orderId": "order_id",
  "payerId": "user_id",
  "payeeId": "seller_id",
  "amount": 50000,
  "currency": "RWF",
  "paymentMethod": "PaymentMethod.mtnMomo",
  "status": "PaymentStatus.completed",
  "transactionId": "ITRACE_123456789_1234567890",
  "externalTransactionId": "EXT_123456789",
  "phoneNumber": "250781234567",
  "createdAt": "2025-01-30T10:00:00Z",
  "completedAt": "2025-01-30T10:01:30Z",
  "webhookData": {...}
}
```

## Security Features

- **API Key Encryption**: Secure credential storage
- **Transaction Validation**: Amount and phone number verification
- **Webhook Authentication**: Signature verification
- **Rate Limiting**: Prevent abuse
- **Audit Logging**: Complete transaction history

## Testing

### Sandbox Environment
- Use sandbox credentials for testing
- Test with sandbox phone numbers
- Verify webhook responses
- Check error handling

### Test Cases
- ✅ Successful payment flow
- ✅ Payment rejection
- ✅ Invalid phone number
- ✅ Insufficient balance
- ✅ Network timeout
- ✅ Webhook processing

## Production Deployment

### Pre-deployment Checklist:
- [ ] Production API credentials configured
- [ ] Webhook endpoints live and tested
- [ ] SSL certificates installed
- [ ] Payment limits configured
- [ ] Monitoring and alerts set up
- [ ] Customer support trained

### Go-live Process:
1. Switch from sandbox to production credentials
2. Update webhook URLs to production endpoints
3. Test with small amounts
4. Monitor transaction success rates
5. Scale up based on performance

## Troubleshooting

### Common Issues:

#### Payment Not Initiating:
- Check API credentials
- Verify phone number format
- Ensure sufficient balance

#### Webhook Not Received:
- Check webhook URL accessibility
- Verify SSL certificates
- Confirm firewall settings

#### Payment Status Stuck:
- Check provider API status
- Verify network connectivity
- Review error logs

### Support Contacts:
- **MTN MoMo**: developer@mtn.co.rw
- **Airtel Money**: developer@airtel.rw
- **iTraceLink Support**: support@itracelink.rw

## Future Enhancements

- [ ] **Payment Plans**: Installment payments
- [ ] **Bulk Payments**: Multiple order payments
- [ ] **Payment Links**: Shareable payment URLs
- [ ] **Recurring Payments**: Subscription-based payments
- [ ] **Payment Analytics**: Advanced reporting
- [ ] **Multi-currency Support**: USD, EUR integration
- [ ] **QR Code Payments**: Mobile app integration

---

## Quick Start for Developers

1. **Configure Environment**:
   ```bash
   cp .env.example .env
   # Edit .env with your credentials
   ```

2. **Initialize Payment Service**:
   ```dart
   PaymentService().initialize();
   ```

3. **Process Payment**:
   ```dart
   final request = PaymentRequest(
     phoneNumber: '250781234567',
     amount: 50000,
     currency: 'RWF',
     reference: 'ORDER_123',
     description: 'Payment for beans',
   );

   final response = await PaymentService().processPayment(
     PaymentMethod.mtnMomo,
     request,
   );
   ```

4. **Check Status**:
   ```dart
   final status = await PaymentService().checkPaymentStatus(
     PaymentMethod.mtnMomo,
     'transaction_id',
   );
   ```

## Compliance

This implementation complies with:
- **Rwanda Financial Regulations**
- **Mobile Money Provider Guidelines**
- **Data Protection Standards**
- **PCI DSS Requirements**

For detailed compliance information, contact legal@itracelink.rw
