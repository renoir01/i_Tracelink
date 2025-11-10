# 💳 Payment API Setup Guide

## ⚠️ CURRENT STATUS

Your `.env` file has been updated with payment API configuration, but you need to add your actual API credentials.

**Current credentials are placeholders:**
```
MTN_MOMO_API_KEY=your_mtn_api_key_here  ← REPLACE THIS
MTN_MOMO_API_SECRET=your_mtn_api_secret_here  ← REPLACE THIS
```

---

## 🚀 HOW TO GET MTN MOMO SANDBOX CREDENTIALS

### Step 1: Create MTN MoMo Developer Account
1. Go to: https://momodeveloper.mtn.com/
2. Click **"Sign Up"**
3. Fill in your details and verify email

### Step 2: Subscribe to Products
1. Login to your account
2. Go to **"Products"**
3. Subscribe to:
   - **Collection** (for receiving payments)
   - **Disbursement** (for sending money)

### Step 3: Get API Credentials
1. Go to **"Sandbox User Provisioning"**
2. Create a new user
3. Get your:
   - **API Key** (Subscription Key)
   - **API Secret** (from API User creation)
   - **Collection Account** (User ID)

### Step 4: Update .env File
```
MTN_MOMO_API_KEY=abc123...
MTN_MOMO_API_SECRET=xyz789...
MTN_COLLECTION_ACCOUNT=your-user-id
```

---

## 🌍 HOW TO GET AIRTEL MONEY CREDENTIALS

### Step 1: Register for Airtel Money API
1. Go to: https://developers.africa.airtel.com/
2. Click **"Register"**
3. Complete registration

### Step 2: Create Application
1. Login to developer portal
2. Create new application
3. Select **"Airtel Money"** product

### Step 3: Get Credentials
1. Go to your application dashboard
2. Copy:
   - **Client ID** (API Key)
   - **Client Secret** (API Secret)

### Step 4: Update .env File
```
AIRTEL_API_KEY=your-client-id
AIRTEL_API_SECRET=your-client-secret
```

---

## ✅ QUICK START (For Testing Without Real APIs)

If you just want to test the UI without real payment processing:

### Option 1: Use Mock Credentials (Testing Only)
Update your `.env` with these test values:

```
# MTN MoMo Test Credentials (won't actually process payments)
MTN_MOMO_API_KEY=test_mtn_key_12345
MTN_MOMO_API_SECRET=test_mtn_secret_67890
MTN_COLLECTION_ACCOUNT=test_collection_account

# Airtel Money Test Credentials (won't actually process payments)
AIRTEL_API_KEY=test_airtel_key_12345
AIRTEL_API_SECRET=test_airtel_secret_67890
```

**Note:** These won't actually process payments, but will allow you to test the UI and flow!

---

## 🎯 RECOMMENDED: Start with Mock Testing

**For development and testing:**
1. ✅ Use mock credentials (above)
2. ✅ Test the payment flow UI
3. ✅ Test payment status tracking
4. ✅ Test Firestore payment records

**For production:**
1. Get real MTN MoMo credentials
2. Get real Airtel Money credentials
3. Replace mock credentials with real ones

---

## 📝 AFTER UPDATING .ENV

### 1. Restart the App
```bash
flutter run
```

### 2. Test Payment
1. Login as admin
2. Click Developer Tools
3. Click "Test Payments"
4. Try a test payment

### 3. Check Results
- Payment record created in Firestore ✅
- Payment status updates ✅
- UI shows payment flow ✅

---

## ⚠️ IMPORTANT NOTES

### Security
- **NEVER** commit `.env` file to Git
- **NEVER** share API credentials publicly
- Use sandbox credentials for testing only

### Testing vs Production
- **Sandbox/Test**: Use test credentials and test phone numbers
- **Production**: Use real credentials and real phone numbers
- Always test thoroughly in sandbox before going live

---

## 🐛 TROUBLESHOOTING

### "Failed to get access token"
- Check API credentials are correct
- Verify you subscribed to the right products
- Check internet connection
- For MTN: Ensure you created sandbox user

### Payment Fails Immediately
- Check phone number format (must be international: +250...)
- Verify payment method matches phone number (MTN vs Airtel)
- Check amount is within allowed limits

### Status Never Updates
- Check callback URL is accessible
- Verify Firestore rules allow updates
- Check payment service is polling correctly

---

## 💡 CURRENT STATUS

**What works NOW (with mock credentials):**
- ✅ Payment UI and forms
- ✅ Payment record creation
- ✅ Status tracking
- ✅ Payment history

**What needs real credentials:**
- ❌ Actual money transfer
- ❌ Real payment confirmation
- ❌ SMS notifications from payment providers

---

## 🎯 NEXT STEPS

1. **For UI testing**: Use mock credentials and restart app
2. **For real payments**: Get MTN/Airtel credentials
3. **For production**: Set up proper callback URLs and webhooks

---

**Need help getting credentials? Let me know!** 🚀
