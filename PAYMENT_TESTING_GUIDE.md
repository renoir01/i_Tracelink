# 🧪 Payment Testing Guide

## ✅ Testing Setup Complete!

**Date**: November 3, 2025 - 2:30 PM  
**Status**: Ready to Test

---

## 🎯 What's Been Created

### **1. Payment Test Screen** ✅
- Interactive payment testing UI
- Phone number validation
- Amount validation
- Quick test buttons (Success, Fail, Timeout)
- Real-time payment method selection

### **2. Payment Status Screen** ✅
- Real-time status updates
- Payment timeline
- Detailed payment info
- Error handling
- Auto-refresh via StreamBuilder

### **3. Developer Tools Screen** ✅
- Payment testing access
- View all payments
- Database statistics
- Clear test data
- Environment info

---

## 🚀 How to Test

### **Step 1: Access Developer Tools**

**Option A - Via Admin Dashboard**:
1. Login as admin
2. Look for 🔧 Developer Tools icon in top right
3. Click to open Developer Tools screen
4. Click "Test Payments"

**Option B - Direct Navigation**:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PaymentTestScreen(),
  ),
);
```

---

### **Step 2: Configure Environment**

Make sure `.env` file exists in project root:

```env
# MTN MoMo - Sandbox
MTN_MOMO_API_KEY=your_subscription_key
MTN_MOMO_API_SECRET=your_api_secret
MTN_MOMO_BASE_URL=https://sandbox.momodeveloper.mtn.com
MTN_COLLECTION_ACCOUNT=your_api_user_uuid

# Airtel Money - Sandbox
AIRTEL_API_KEY=your_client_id
AIRTEL_API_SECRET=your_client_secret
AIRTEL_BASE_URL=https://openapiuat.airtel.africa
```

**Don't have credentials yet?**
- The test will run but may fail at API call
- See `PAYMENT_API_SETUP_GUIDE.md` for registration
- Takes ~30 minutes to get sandbox credentials

---

### **Step 3: Run Test Payment**

**Quick Test (Recommended)**:
1. Open Payment Test Screen
2. Click one of the quick test buttons:
   - **"Success Test"** - Simulates successful payment
   - **"Fail Test"** - Simulates failed payment
   - **"Timeout Test"** - Simulates timeout scenario
3. Watch payment status update in real-time!

**Manual Test**:
1. Select payment method (MTN MoMo / Airtel Money)
2. Enter phone number (use test numbers)
3. Enter amount (e.g., 1000 RWF)
4. Click "Process Test Payment"
5. Navigate to status screen
6. Watch real-time updates!

---

### **Step 4: Test Scenarios**

#### **Scenario 1: Successful Payment** ✅
```
Phone: 46733123450
Amount: 1000
Expected: Status changes to "Completed"
Timeline: ~10-20 seconds
```

#### **Scenario 2: Failed Payment** ❌
```
Phone: 46733123451
Amount: 2000
Expected: Status changes to "Failed"
Timeline: ~10-20 seconds
```

#### **Scenario 3: Timeout** ⏱️
```
Phone: 46733123452
Amount: 3000
Expected: Status stays "Processing" then times out
Timeline: ~2 minutes
```

#### **Scenario 4: Insufficient Balance** ⚠️
```
Phone: 46733123453
Amount: 4000
Expected: Status changes to "Failed" with error message
Timeline: ~10-20 seconds
```

#### **Scenario 5: Invalid Phone Number** 📞
```
Phone: 46733123454
Amount: 5000
Expected: Status changes to "Failed" with error message
Timeline: ~10-20 seconds
```

#### **Scenario 6: Server Error** 🚨
```
Phone: 46733123455
Amount: 6000
Expected: Status changes to "Failed" with error message
Timeline: ~10-20 seconds
```

---

## 📱 Test Phone Numbers (MTN Sandbox)

| Number | Expected Result | Use Case |
|--------|----------------|----------|
| 46733123450 | Success | Test successful payment flow |
| 46733123451 | Failed | Test error handling |
| 46733123452 | Timeout | Test timeout handling |
| 46733123453 | Ongoing | Test long processing |
| 46733123454 | Invalid Phone Number | Test invalid phone number handling |
| 46733123455 | Server Error | Test server error handling |

---

## 🔍 What to Watch For

### **1. Payment Record Creation**
- Check Firestore `payments` collection
- Should create record immediately
- Status starts

### **2. Payment Status Updates**
- Check payment status screen
- Should update in real-time
- Should reflect correct status

### **3. Error Handling**
- Check error messages
- Should display correct error message
- Should handle errors correctly

### **4. Timeout Handling**
- Check timeout handling
- Should handle timeouts correctly
- Should display correct error message

### **5. Server Error Handling**
- Check server error handling
- Should handle server errors correctly
- Should display correct error message
