# 🔥 Firebase Setup - Critical Next Steps

## ⚠️ IMPORTANT: Complete These Steps Before Running the App

Your Flutter app is fully configured and ready, but you need to complete the Firebase setup:

---

## Step 1: Download google-services.json from Firebase Console

### Instructions:

1. **Go to Firebase Console:**
   - URL: https://console.firebase.google.com
   - Project: **itracelink** (the one you just created)

2. **Navigate to Project Settings:**
   - Click the gear icon ⚙️ next to "Project Overview"
   - Select "Project settings"
   - Scroll to "Your apps" section

3. **Register Android App (if not done):**
   - Click "Add app" → Select Android icon
   - **Android package name:** `rw.itracelink.app`
   - **App nickname:** iTraceLink
   - Click "Register app"

4. **Download the Config File:**
   - Download `google-services.json`
   - This file contains your Firebase project configuration

5. **Place the File:**
   ```
   📁 itracelink/
   └── 📁 android/
       └── 📁 app/
           └── 📄 google-services.json  ← PUT IT HERE!
   ```

---

## Step 2: Enable Firebase Services

### In Firebase Console, enable these services:

### 🔐 Authentication
1. Go to: Build → Authentication
2. Click "Get Started"
3. Enable "Email/Password" sign-in method
4. (Optional) Enable "Phone" for SMS OTP

### 📊 Cloud Firestore
1. Go to: Build → Firestore Database
2. Click "Create database"
3. Select "Start in test mode" (for development)
4. Choose location: **europe-west3** (Belgium - closest to Rwanda)

### 📦 Cloud Storage
1. Go to: Build → Storage
2. Click "Get Started"
3. Start in test mode

### 📱 Cloud Messaging (FCM)
- Already enabled automatically

---

## Step 3: Configure Firestore Security Rules

In Firestore → Rules tab, paste these rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Allow read for authenticated users
    match /{document=**} {
      allow read: if request.auth != null;
    }
    
    // Users collection
    match /users/{userId} {
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Cooperatives
    match /cooperatives/{coopId} {
      allow write: if request.auth != null;
    }
    
    // Orders
    match /orders/{orderId} {
      allow create: if request.auth != null;
      allow update: if request.auth != null;
    }
    
    // Notifications
    match /notifications/{notifId} {
      allow read, update: if request.auth != null && 
                            resource.data.userId == request.auth.uid;
    }
  }
}
```

---

## Step 4: Verify Android Configuration

Check that these files exist and are correct:

### ✅ android/app/build.gradle
```gradle
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
    id "com.google.gms.google-services"  ← Must be here
}

android {
    namespace = "rw.itracelink.app"  ← Correct package name
    defaultConfig {
        applicationId = "rw.itracelink.app"  ← Must match
        minSdk = 21  ← Required by Firebase
        multiDexEnabled true  ← Required
    }
}
```

### ✅ android/settings.gradle
```gradle
plugins {
    id "com.google.gms.google-services" version "4.4.0" apply false  ← Must be here
}
```

---

## Step 5: Test the Setup

### Run these commands:

```bash
# Clean build
flutter clean

# Get dependencies
flutter pub get

# Build APK (this will verify Firebase setup)
flutter build apk --debug
```

### If successful, run the app:
```bash
flutter run
```

---

## 🎯 Expected Behavior After Setup

1. **Splash Screen** → Shows app logo and name
2. **Language Selection** → Choose English or Kinyarwanda
3. **User Type Selection** → Choose your role (5 options)
4. **Registration** → Create account with email/password
5. **Dashboard** → View your dashboard (basic version)

---

## 🐛 Common Issues & Solutions

### Issue: "google-services.json not found"
**Solution:** Make sure the file is in `android/app/` NOT `android/`

### Issue: "Default FirebaseApp is not initialized"
**Solution:** 
1. Delete the app from Firebase Console
2. Re-register with exact package name: `rw.itracelink.app`
3. Download new google-services.json

### Issue: "Execution failed for task ':app:processDebugGoogleServices'"
**Solution:** Package name mismatch. Check:
- google-services.json → "package_name" field
- android/app/build.gradle → "applicationId"
They MUST match exactly: `rw.itracelink.app`

### Issue: Build fails with dependency errors
**Solution:**
```bash
flutter clean
flutter pub cache repair
flutter pub get
```

---

## 📋 Checklist Before Running

- [ ] google-services.json downloaded and placed in `android/app/`
- [ ] Firebase Authentication enabled (Email/Password)
- [ ] Cloud Firestore created (test mode)
- [ ] Cloud Storage enabled (test mode)
- [ ] Firestore security rules configured
- [ ] Package name matches in all places: `rw.itracelink.app`
- [ ] Ran `flutter pub get` successfully
- [ ] No errors in Android configuration files

---

## 🚀 Once Complete

After completing all steps above, you're ready to:
1. Run the app on emulator or device
2. Create test user accounts for all user types
3. Start building user-specific features
4. Integrate SMS (Africa's Talking)
5. Add Google Maps
6. Implement traceability features

---

## 📞 Need Help?

### Common Commands:
```bash
# Check Flutter setup
flutter doctor

# Clean and rebuild
flutter clean && flutter pub get && flutter run

# View logs
flutter logs

# Install on connected device
flutter install
```

### Resources:
- Firebase Console: https://console.firebase.google.com
- Flutter Docs: https://docs.flutter.dev
- Firebase Flutter: https://firebase.flutter.dev

---

**Status:** ⚠️ Firebase configuration required  
**Priority:** HIGH - Must complete before running app  
**Time Estimate:** 15-20 minutes
