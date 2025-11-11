# 🚨 URGENT MANUAL ACTIONS REQUIRED

**DO NOT DEPLOY TO PRODUCTION UNTIL THESE ARE COMPLETED**

## Overview

This document outlines the 2 critical security issues that require **immediate manual action**. These cannot be automated and must be completed by you before deploying the app to production.

**Estimated Time:** 2-3 hours
**Urgency:** CRITICAL - Do this ASAP

---

## 1. 🔐 Revoke Exposed API Credentials (URGENT - 30 minutes)

### ❌ Problem

Your `.env` file containing real API keys was committed to the git repository in commit `bd63f40` (project design). Anyone with repository access can see these credentials and use them.

### 🔍 Exposed Credentials

```env
AFRICAS_TALKING_API_KEY=atsk_62eee19abc7628917b9b8860e46bf744b29558de30c390c1935115cbedd5f63d30ca7cfb
AFRICAS_TALKING_SENDER_ID=AFRICASTKNG
MTN_MOMO_API_KEY=test_mtn_key_12345
AIRTEL_API_KEY=test_airtel_key_12345
```

### ⚠️ Security Risk

- Anyone can send SMS messages on your Africa's Talking account (costs money!)
- Unauthorized access to payment API endpoints
- Potential account suspension for misuse
- Financial loss from unauthorized usage

### ✅ Required Actions

#### Step 1: Revoke Africa's Talking API Key (URGENT)

1. **Login to Africa's Talking Dashboard**
   - Go to: https://account.africastalking.com/
   - Login with your credentials

2. **Navigate to API Settings**
   - Click on "Settings" in the top navigation
   - Select "API Key" from the sidebar

3. **Regenerate API Key**
   - Click "Regenerate API Key" button
   - Copy the new API key (it will only be shown once!)
   - Save it securely in a password manager

4. **Update Local .env File**
   ```bash
   # Edit .env file (already in .gitignore)
   AFRICAS_TALKING_API_KEY=NEW_KEY_HERE
   AFRICAS_TALKING_USERNAME=YOUR_USERNAME
   AFRICAS_TALKING_SENDER_ID=AFRICASTKNG
   ```

#### Step 2: Revoke Test Payment Keys

If these are real test keys (not placeholders):

1. **MTN Mobile Money**
   - Contact MTN MoMo support: momo@mtn.com
   - Request to revoke test API key: `test_mtn_key_12345`
   - Request new test credentials

2. **Airtel Money**
   - Contact Airtel Money support
   - Request to revoke test API key: `test_airtel_key_12345`
   - Request new test credentials

#### Step 3: Remove .env from Git History

**WARNING:** This rewrites git history. Coordinate with your team first!

**Option 1: Using git filter-repo (Recommended)**

```bash
# Install git filter-repo
pip install git-filter-repo

# Remove .env from all commits
git filter-repo --path .env --invert-paths

# Force push (WARNING: All team members need to re-clone)
git push origin --force --all
```

**Option 2: Using BFG Repo-Cleaner**

```bash
# Download BFG
wget https://repo1.maven.org/maven2/com/madgag/bfg/1.14.0/bfg-1.14.0.jar

# Remove .env file from history
java -jar bfg-1.14.0.jar --delete-files .env

# Clean up
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# Force push
git push origin --force --all
```

#### Step 4: Use Environment-Specific Configuration

For future deployments:

**Development (Local):**
```bash
# Keep .env locally (already in .gitignore)
.env
```

**Production (CI/CD):**

If using GitHub Actions:
```yaml
# .github/workflows/deploy.yml
- name: Create .env
  run: |
    echo "AFRICAS_TALKING_API_KEY=${{ secrets.AFRICAS_TALKING_API_KEY }}" > .env
    echo "AFRICAS_TALKING_USERNAME=${{ secrets.AFRICAS_TALKING_USERNAME }}" >> .env
```

Add secrets in GitHub:
- Settings → Secrets and variables → Actions → New repository secret

**Status Checklist:**
- [ ] Africa's Talking API key regenerated
- [ ] New API key saved securely
- [ ] Local .env file updated with new key
- [ ] MTN MoMo test key revoked (if real)
- [ ] Airtel Money test key revoked (if real)
- [ ] .env removed from git history
- [ ] Team notified to re-clone repository
- [ ] CI/CD secrets configured

---

## 2. 🔑 Generate Production Keystore (CRITICAL - 1 hour)

### ❌ Problem

Your release APK is currently signed with **debug keys** instead of production keys. This means:
- Google Play Store will **REJECT** your app
- Anyone can repackage and modify your APK
- No security or integrity guarantees

**Location:** `android/app/build.gradle:35`
```gradle
signingConfig = signingConfigs.debug  // ❌ CRITICAL BUG
```

### ✅ Required Actions

#### Step 1: Generate Production Keystore

**IMPORTANT:** The keystore password and alias you choose CANNOT be changed later. If you lose this keystore, you can NEVER update your app on Google Play Store!

```bash
# Navigate to Android app directory
cd android/app

# Create keystore directory
mkdir -p keystore

# Generate keystore (you'll be prompted for information)
keytool -genkey -v -keystore keystore/itracelink-release.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias itracelink-key

# You'll be prompted for:
# 1. Keystore password (SAVE THIS SECURELY!)
# 2. Key password (can be same as keystore password)
# 3. Your name (Organization name)
# 4. Organization unit (e.g., "Development")
# 5. Organization (e.g., "iTraceLink")
# 6. City/Locality (e.g., "Kigali")
# 7. State/Province (e.g., "Kigali City")
# 8. Country code (e.g., "RW")
```

**Example interaction:**
```
Enter keystore password: MySecurePassword123!
Re-enter new password: MySecurePassword123!
What is your first and last name?
  [Unknown]:  iTraceLink Team
What is the name of your organizational unit?
  [Unknown]:  Development
What is the name of your organization?
  [Unknown]:  iTraceLink
What is the name of your City or Locality?
  [Unknown]:  Kigali
What is the name of your State or Province?
  [Unknown]:  Kigali City
What is the two-letter country code for this unit?
  [Unknown]:  RW
Is CN=iTraceLink Team, OU=Development, O=iTraceLink, L=Kigali, ST=Kigali City, C=RW correct?
  [no]:  yes

Enter key password for <itracelink-key>
	(RETURN if same as keystore password): [Press RETURN]
```

#### Step 2: Backup Keystore Securely

**CRITICAL:** If you lose this keystore, you can NEVER update your app!

1. **Copy keystore to 3 secure locations:**
   - Password manager (1Password, LastPass, Bitwarden)
   - Encrypted USB drive
   - Secure cloud storage (Google Drive with encryption)

2. **Save keystore information:**
   ```
   Keystore File: android/app/keystore/itracelink-release.jks
   Keystore Password: [YOUR_PASSWORD]
   Key Alias: itracelink-key
   Key Password: [YOUR_KEY_PASSWORD]
   ```

#### Step 3: Create Key Properties File

Create `android/key.properties` (already in .gitignore):

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=itracelink-key
storeFile=keystore/itracelink-release.jks
```

**DO NOT commit this file to git!**

#### Step 4: Update build.gradle

Edit `android/app/build.gradle`:

```gradle
// Add this BEFORE the android block
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing code ...

    // Add signingConfigs BEFORE buildTypes
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            // Change from signingConfig = signingConfigs.debug to:
            signingConfig signingConfigs.release

            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

#### Step 5: Test Release Build

```bash
# Navigate to project root
cd /home/user/i_Tracelink

# Clean previous builds
flutter clean

# Build release APK
flutter build apk --release

# The signed APK will be at:
# build/app/outputs/flutter-apk/app-release.apk
```

#### Step 6: Verify Signing

```bash
# Verify the APK is signed with your new keystore
keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk

# You should see your organization info:
# Owner: CN=iTraceLink Team, OU=Development, O=iTraceLink, L=Kigali, ST=Kigali City, C=RW
```

#### Step 7: Set Up CI/CD Signing (Optional but Recommended)

For GitHub Actions:

1. **Convert keystore to base64:**
   ```bash
   base64 android/app/keystore/itracelink-release.jks > keystore.base64
   ```

2. **Add to GitHub Secrets:**
   - `KEYSTORE_BASE64`: Contents of keystore.base64 file
   - `KEYSTORE_PASSWORD`: Your keystore password
   - `KEY_ALIAS`: itracelink-key
   - `KEY_PASSWORD`: Your key password

3. **Update CI workflow to decode keystore:**
   ```yaml
   - name: Decode keystore
     run: |
       echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 -d > android/app/keystore/itracelink-release.jks
   ```

**Status Checklist:**
- [ ] Production keystore generated
- [ ] Keystore backed up to 3 secure locations
- [ ] Keystore information saved in password manager
- [ ] key.properties file created (NOT committed)
- [ ] build.gradle updated with signing configuration
- [ ] Release APK built successfully
- [ ] APK signing verified with keytool
- [ ] CI/CD secrets configured (if applicable)

---

## 3. 📤 Deploy Updated Firestore Rules

### Required Action

The new Firestore security rules are in your codebase but need to be deployed to Firebase.

#### Option 1: Deploy via Firebase CLI (Recommended)

```bash
# Install Firebase CLI (if not already installed)
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in your project (if not done)
firebase init firestore

# Deploy only Firestore rules
firebase deploy --only firestore:rules

# You should see:
# ✔  firestore: released rules firestore.rules to cloud.firestore
```

#### Option 2: Deploy via Firebase Console

1. Go to: https://console.firebase.google.com/
2. Select your project: `itracelink-8c4ea`
3. Navigate to: Firestore Database → Rules
4. Copy contents from `firestore.rules` in your project
5. Paste into the rules editor
6. Click "Publish"

#### Step 3: Test Rules

Test with different user accounts:

```bash
# Install Firebase emulator
npm install -g firebase-tools

# Start emulator
firebase emulators:start --only firestore

# Run your app against the emulator
# Edit lib/main.dart to connect to emulator (for testing only)
```

**Status Checklist:**
- [ ] Firebase CLI installed
- [ ] Logged into Firebase
- [ ] Firestore rules deployed
- [ ] Rules tested with different user roles
- [ ] Verified admin-only collections are protected

---

## 4. 📱 Test APK Installation

### Required Action

After generating the production keystore and building the release APK, test it on a physical device.

```bash
# Build release APK
flutter build apk --release

# Install on connected Android device
adb install build/app/outputs/flutter-apk/app-release.apk

# Or transfer APK to device and install manually
```

**Test Cases:**
1. App installs without "app has stopped" error
2. Firebase authentication works
3. Firestore data loads correctly
4. All screens accessible based on user role
5. Admin panel only accessible to admins
6. Crashlytics reports errors

**Status Checklist:**
- [ ] Release APK built successfully
- [ ] APK installed on physical device
- [ ] App launches without crashing
- [ ] Authentication works
- [ ] Data loads from Firestore
- [ ] Role-based access control working
- [ ] No critical errors in logs

---

## Summary Checklist

### 🔴 Critical (Do Immediately)
- [ ] Revoke Africa's Talking API key
- [ ] Generate production keystore
- [ ] Update build.gradle with signing config
- [ ] Deploy Firestore rules to Firebase

### 🟡 High Priority (Before Launch)
- [ ] Remove .env from git history
- [ ] Test release APK on physical device
- [ ] Verify all security rules working
- [ ] Set up CI/CD secrets

### 🟢 Medium Priority (Before Scaling)
- [ ] Backup keystore to multiple locations
- [ ] Document keystore recovery procedure
- [ ] Set up Firebase monitoring alerts
- [ ] Create incident response plan

---

## Need Help?

If you encounter issues:

1. **Firebase Documentation**
   - Firestore Rules: https://firebase.google.com/docs/firestore/security/get-started
   - App Signing: https://developer.android.com/studio/publish/app-signing

2. **Android Keystore Issues**
   - If you lose your keystore, you CANNOT update your app
   - Always keep 3+ backups in secure locations
   - Test keystore before publishing to Play Store

3. **API Key Rotation**
   - Document all API key rotation in a secure log
   - Update all environments (dev, staging, prod)
   - Monitor for unauthorized usage after rotation

---

**Last Updated:** 2025-11-11
**Status:** INCOMPLETE - MANUAL ACTION REQUIRED
**Next Review:** After completing all checklists above
