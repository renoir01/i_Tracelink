# 🔨 How to Build APK - Quick Guide

**Follow these steps on your LOCAL MACHINE (not in cloud environment)**

---

## 📋 Prerequisites

- ✅ Flutter installed (version 3.5.4+)
- ✅ Android SDK installed
- ✅ Git installed
- ✅ Android device for testing

---

## 🚀 Quick Build (3 Steps)

### Step 1: Pull Latest Code

```bash
# Clone or navigate to project
cd ~/path/to/i_Tracelink

# Checkout the correct branch
git checkout claude/check-environment-011CUzvNRECg8HmrDvsHmoi2

# Pull latest changes
git pull origin claude/check-environment-011CUzvNRECg8HmrDvsHmoi2
```

### Step 2: Run Build Script

**On macOS/Linux:**
```bash
./build_apk.sh
```

**On Windows:**
```cmd
build_apk.bat
```

The script will:
1. ✅ Check Flutter installation
2. ✅ Check Firebase configuration
3. ✅ Clean previous builds
4. ✅ Get dependencies
5. ✅ Build release APK
6. ✅ Copy APK to Desktop/iTraceLink_Submission/

### Step 3: Test APK

1. Transfer `iTraceLink-v1.0.apk` to your Android phone
2. Install and test core features
3. Follow `BUILD_AND_SUBMIT_CHECKLIST.md` for complete testing

---

## 🎯 Expected Result

After running the build script, you'll have:

```
📱 APK File:
   ~/Desktop/iTraceLink_Submission/iTraceLink-v1.0.apk
   Size: ~45MB

✅ Ready for:
   - Installation on Android device
   - Testing core features
   - Submission to instructor
```

---

## ⚠️ Troubleshooting

**Script won't run (macOS/Linux):**
```bash
chmod +x build_apk.sh
./build_apk.sh
```

**"Flutter not found":**
- Install Flutter: https://flutter.dev/docs/get-started/install
- Or add to PATH: `export PATH="$PATH:/path/to/flutter/bin"`

**"Firebase configuration missing":**
1. Go to https://console.firebase.google.com
2. Select "i-tracelink" project
3. Download `google-services.json`
4. Place in `android/app/google-services.json`

**Build fails:**
```bash
# Try manual build
flutter clean
flutter pub get
flutter build apk --release
```

---

## 📚 Full Documentation

For comprehensive guidance, see:
- **BUILD_AND_SUBMIT_CHECKLIST.md** - Complete submission guide
- **INSTALLATION_AND_SETUP_GUIDE.md** - Detailed setup instructions
- **VIDEO_DEMONSTRATION_SCRIPT.md** - How to record demo video
- **TESTING_DOCUMENTATION.md** - Testing requirements

---

## 🆘 Need Help?

**Common Commands:**

```bash
# Check Flutter version
flutter --version

# Check Flutter setup
flutter doctor

# Manual build
flutter clean
flutter pub get
flutter build apk --release

# Find APK
ls -lh build/app/outputs/flutter-apk/app-release.apk
```

---

**Good luck! 🚀**
