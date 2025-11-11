# 📦 Installation and Setup Guide - iTraceLink

**Complete step-by-step instructions for installing and running the iTraceLink application**

---

## Table of Contents

1. [System Requirements](#system-requirements)
2. [Installation Steps](#installation-steps)
3. [Firebase Configuration](#firebase-configuration)
4. [Running the Application](#running-the-application)
5. [Building Release APK](#building-release-apk)
6. [Testing User Accounts](#testing-user-accounts)
7. [Troubleshooting](#troubleshooting)

---

## System Requirements

### Hardware Requirements

**Minimum:**
- RAM: 4GB
- Storage: 2GB free space
- Android device with Android 6.0+ (API 23+) or iOS 11+

**Recommended:**
- RAM: 8GB+
- Storage: 5GB+ free space
- Android device with Android 10+ (API 29+)
- Physical device for testing (emulators may have performance issues)

### Software Requirements

1. **Flutter SDK**: Version 3.5.4 or higher
   - Download from: https://docs.flutter.dev/get-started/install

2. **Android Studio** (for Android development):
   - Version 2023.1.1 or higher
   - Android SDK 33 or higher
   - Java JDK 11 or higher

3. **VS Code** (Alternative IDE):
   - Flutter extension
   - Dart extension

4. **Firebase CLI** (optional but recommended):
   ```bash
   npm install -g firebase-tools
   ```

5. **Git**:
   - For cloning the repository

---

## Installation Steps

### Step 1: Clone the Repository

```bash
# Navigate to your desired directory
cd ~/projects

# Clone the repository
git clone https://github.com/renoir01/i_Tracelink.git

# Navigate into the project directory
cd i_Tracelink
```

### Step 2: Install Flutter Dependencies

```bash
# Clean any previous builds
flutter clean

# Get all required packages
flutter pub get

# Verify Flutter installation
flutter doctor
```

**Expected output:**
```
Doctor summary (to see all details, run flutter doctor -v):
[✓] Flutter (Channel stable, 3.5.4, on Linux, locale en_US.UTF-8)
[✓] Android toolchain - develop for Android devices
[✓] Chrome - develop for the web
[✓] Android Studio (version 2023.1)
[✓] VS Code (version 1.85)
[✓] Connected device (1 available)
```

**If you see any issues with Flutter doctor, resolve them before proceeding.**

### Step 3: Verify Project Structure

Ensure these critical files exist:

```bash
ls -la android/app/google-services.json        # Firebase config
ls -la lib/firebase_options.dart                # Firebase options
ls -la .env.example                             # Environment template
ls -la android/app/proguard-rules.pro          # ProGuard rules
```

---

## Firebase Configuration

### Step 1: Firebase Project Setup

**If you already have Firebase configured, skip to Step 3.**

1. **Go to Firebase Console**
   - Visit: https://console.firebase.google.com/
   - Click "Add Project" or select existing project `itracelink-8c4ea`

2. **Enable Required Services**
   - **Authentication**: Email/Password provider
   - **Cloud Firestore**: Database for storing data
   - **Storage**: For images and documents
   - **Firebase Messaging**: For push notifications
   - **Crashlytics**: For error reporting

### Step 2: Download Configuration Files

**For Android:**
1. In Firebase Console → Project Settings → General
2. Scroll to "Your apps" section
3. Click on Android app (package: `rw.itracelink.app`)
4. Download `google-services.json`
5. Place it in: `android/app/google-services.json`

**For iOS (if applicable):**
1. Download `GoogleService-Info.plist`
2. Place it in: `ios/Runner/GoogleService-Info.plist`

### Step 3: Deploy Firestore Security Rules

The project includes secure Firestore rules that must be deployed:

```bash
# Login to Firebase
firebase login

# Initialize Firebase (if not already done)
firebase init firestore

# Deploy Firestore rules
firebase deploy --only firestore:rules
```

**Alternatively, deploy via Firebase Console:**
1. Go to Firestore Database → Rules
2. Copy contents from `firestore.rules` in the project
3. Paste and click "Publish"

### Step 4: Create Environment File

```bash
# Copy the example environment file
cp .env.example .env

# Edit .env with your credentials (use a text editor)
nano .env
```

**Required variables:**
```env
# Africa's Talking (for SMS notifications)
AFRICAS_TALKING_API_KEY=your_api_key_here
AFRICAS_TALKING_USERNAME=your_username_here
AFRICAS_TALKING_SENDER_ID=AFRICASTKNG

# MTN Mobile Money (for payments)
MTN_MOMO_API_KEY=your_mtn_key_here
MTN_MOMO_SUBSCRIPTION_KEY=your_subscription_key_here

# Airtel Money (for payments)
AIRTEL_API_KEY=your_airtel_key_here
AIRTEL_CLIENT_ID=your_client_id_here

# Sendgrid (for email notifications)
SENDGRID_API_KEY=your_sendgrid_key_here
SENDGRID_FROM_EMAIL=noreply@itracelink.com
```

**⚠️ IMPORTANT:**
- Never commit the `.env` file to git
- Keep your API keys secure
- Use test keys for development

---

## Running the Application

### Option 1: Run on Connected Android Device

```bash
# Connect your Android device via USB
# Enable USB debugging in Developer Options

# Verify device is connected
adb devices

# You should see:
# List of devices attached
# ABC123XYZ    device

# Run the app in debug mode
flutter run

# Or specify the device
flutter run -d ABC123XYZ
```

### Option 2: Run on Android Emulator

```bash
# List available emulators
flutter emulators

# Launch an emulator
flutter emulators --launch Pixel_5_API_33

# Run the app
flutter run
```

### Option 3: Run in Release Mode (Faster)

```bash
# Release mode is optimized and faster
flutter run --release
```

### Expected Startup Sequence

When you run the app, you should see:

```
Launching lib/main.dart on Android SDK built for x86_64 in debug mode...
Running Gradle task 'assembleDebug'...
✓ Built build/app/outputs/flutter-apk/app-debug.apk.
Installing build/app/outputs/flutter-apk/app-debug.apk...
D/FlutterActivity(12345): Using the launch theme as normal theme.
D/FlutterActivityAndFragmentDelegate(12345): Setting up FlutterEngine.
✅ Firebase initialized successfully
✅ Firebase Crashlytics initialized successfully
✅ Payment service initialized successfully
✅ Email service initialized successfully
```

**The app will open with:**
1. Splash screen (2 seconds)
2. Language selection screen (English/Kinyarwanda)
3. User type selection screen
4. Login/Register screen

---

## Building Release APK

### Prerequisites

Before building a release APK, you must:
1. ✅ Have Firebase configured
2. ✅ Have environment variables set up
3. ✅ Have production keystore generated (see `URGENT_MANUAL_ACTIONS_REQUIRED.md`)

### Step 1: Clean Previous Builds

```bash
flutter clean
flutter pub get
```

### Step 2: Build Release APK

```bash
# Build release APK (creates one APK for all architectures)
flutter build apk --release

# Or build split APKs by architecture (smaller size)
flutter build apk --split-per-abi

# Output location:
# build/app/outputs/flutter-apk/app-release.apk
```

### Step 3: Verify APK Size

```bash
# Check APK size (should be under 50MB)
ls -lh build/app/outputs/flutter-apk/app-release.apk

# Expected size: ~25-40 MB
```

### Step 4: Install APK on Device

```bash
# Install via ADB
adb install build/app/outputs/flutter-apk/app-release.apk

# Or transfer APK to device and install manually
```

### Step 5: Verify APK Signing

```bash
# Check APK signature (verify it's signed with your keystore)
keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk

# You should see your organization details
```

---

## Testing User Accounts

For demonstration and testing purposes, you can create accounts for each user type:

### Test Account Creation

1. **Admin Account**
   - Email: `admin@itracelink.com`
   - Password: `Admin123!`
   - Access: Firebase Console → Firestore → `admins` collection

2. **Seed Producer**
   - Register via app → Select "Seed Producer"
   - Complete profile with organization details

3. **Agro-Dealer**
   - Register via app → Select "Agro-Dealer"
   - Add business information and location

4. **Farmer Cooperative**
   - Register via app → Select "Farmer Cooperative"
   - Enter cooperative name and member count

5. **Aggregator**
   - Register via app → Select "Aggregator"
   - Provide trading license information

6. **Institution**
   - Register via app → Select "Institution (School/Hospital)"
   - Enter institution name and requirements

### Test Data Population

```bash
# Use Firebase Console to add test data:
# 1. Navigate to Firestore Database
# 2. Add sample batches for farmers
# 3. Add sample inventory for aggregators
# 4. Create test orders
```

---

## Troubleshooting

### Issue 1: "App has stopped" after installation

**Symptom:** App crashes immediately after launching

**Solution:**
```bash
# Check logcat for errors
adb logcat | grep -i "flutter\|firebase\|error"

# Common causes:
# 1. Missing google-services.json → Add Firebase configuration
# 2. ProGuard issues → Check android/app/proguard-rules.pro
# 3. MultiDex issues → Verify Application.kt is configured
```

### Issue 2: Firebase not initialized

**Symptom:** "Firebase has not been initialized"

**Solution:**
1. Verify `google-services.json` is in `android/app/`
2. Check `lib/firebase_options.dart` exists
3. Run `flutterfire configure` to regenerate

### Issue 3: Gradle build failed

**Symptom:** Gradle sync or build errors

**Solution:**
```bash
# Navigate to android directory
cd android

# Clean Gradle cache
./gradlew clean

# Rebuild
./gradlew build --stacktrace

# If still failing, update Gradle:
# Edit android/gradle/wrapper/gradle-wrapper.properties
# Set: distributionUrl=https\://services.gradle.org/distributions/gradle-8.0-all.zip
```

### Issue 4: Dependencies not resolving

**Symptom:** "Pub get has not been run"

**Solution:**
```bash
# Clear pub cache
flutter pub cache clean

# Get dependencies again
flutter pub get

# If specific package fails:
flutter pub cache repair
```

### Issue 5: Device not detected

**Symptom:** "No devices found"

**Solution:**
```bash
# Verify ADB is working
adb devices

# If no devices:
# 1. Enable USB debugging on Android device
# 2. Accept USB debugging prompt on device
# 3. Try different USB cable/port
# 4. Install/update device drivers

# Restart ADB server
adb kill-server
adb start-server
```

### Issue 6: Hot reload not working

**Symptom:** Changes not reflecting in app

**Solution:**
```bash
# Press 'r' in terminal to hot reload
# Press 'R' in terminal to hot restart

# Or stop and run again:
flutter run
```

### Issue 7: Firestore permission denied

**Symptom:** "PERMISSION_DENIED: Missing or insufficient permissions"

**Solution:**
1. Deploy Firestore rules: `firebase deploy --only firestore:rules`
2. Verify user is authenticated
3. Check user role matches Firestore rule requirements

---

## Performance Optimization

### For Development

```bash
# Enable performance overlay
flutter run --profile

# Analyze app size
flutter build apk --analyze-size

# Check for unnecessary dependencies
flutter pub outdated
```

### For Production

1. **Enable ProGuard** (already configured in `android/app/build.gradle`)
2. **Use release mode** for testing
3. **Compress images** before uploading
4. **Enable caching** for Firestore queries

---

## Next Steps

After successful installation:

1. ✅ Read `TESTING_DOCUMENTATION.md` for testing strategies
2. ✅ Review `DEPLOYMENT_GUIDE.md` for deployment procedures
3. ✅ Check `VIDEO_DEMONSTRATION_SCRIPT.md` for demo guidance
4. ✅ Complete manual actions in `URGENT_MANUAL_ACTIONS_REQUIRED.md`

---

## Support

For issues not covered in this guide:

- **Firebase Issues**: https://firebase.google.com/support
- **Flutter Issues**: https://docs.flutter.dev/get-started/install
- **Project Issues**: Check `PRODUCTION_READINESS_REPORT.md`

---

**Last Updated:** 2025-11-11
**Version:** 1.0
**Tested On:** Android 10+, Flutter 3.5.4
