# iTraceLink - Setup Guide

## Project Overview
iTraceLink is a mobile application for tracking iron-biofortified beans supply chain in Rwanda, from seed to table.

## What Has Been Created

### ✅ Completed Components

#### 1. Project Structure
```
lib/
├── models/               # Data models
│   ├── user_model.dart
│   ├── location_model.dart
│   ├── cooperative_model.dart
│   └── order_model.dart
├── providers/           # State management
│   ├── auth_provider.dart
│   └── language_provider.dart
├── screens/             # UI screens
│   ├── splash_screen.dart
│   ├── language_selection_screen.dart
│   ├── user_type_selection_screen.dart
│   ├── login_screen.dart
│   ├── register_screen.dart
│   └── dashboard_screen.dart
├── services/            # Backend services
│   ├── auth_service.dart
│   └── database_service.dart
├── utils/               # Utilities
│   ├── constants.dart
│   └── app_theme.dart
├── l10n/                # Internationalization
│   ├── app_en.arb       # English translations
│   └── app_rw.arb       # Kinyarwanda translations
└── main.dart            # App entry point
```

#### 2. Features Implemented
- ✅ Splash screen with animation
- ✅ Bilingual support (English/Kinyarwanda)
- ✅ User type selection (5 types)
- ✅ Authentication (Login/Register)
- ✅ Firebase integration setup
- ✅ Material Design 3 theme
- ✅ State management with Provider
- ✅ Responsive UI components

#### 3. Dependencies Configured
All required packages have been added to `pubspec.yaml`:
- Firebase (Auth, Firestore, Storage, Messaging, Analytics, Crashlytics)
- Provider (State Management)
- Google Maps & Location services
- Image handling
- HTTP & API clients
- And more...

#### 4. Android Configuration
- ✅ Package name: `rw.itracelink.app`
- ✅ MinSDK: 21 (Android 5.0+)
- ✅ MultiDex enabled
- ✅ Google Services plugin configured

## 🔥 Firebase Setup Instructions

### Step 1: Register Your Android App in Firebase Console

1. Go to your Firebase console: https://console.firebase.google.com
2. Select your project: **itracelink**
3. Click "Add app" → Select Android
4. Enter the following details:
   - **Android package name:** `rw.itracelink.app`
   - **App nickname:** iTraceLink (optional)
   - **Debug signing certificate SHA-1:** (Optional for now, required for Google Sign-In later)

### Step 2: Download google-services.json

1. After registering the app, download the `google-services.json` file
2. Place it in: `android/app/google-services.json`

**Important:** The file must be in the `android/app/` directory, NOT in `android/`

### Step 3: Enable Firebase Services

In your Firebase Console, enable the following services:

1. **Authentication**
   - Go to Authentication → Sign-in method
   - Enable: Email/Password
   - (Optional) Enable Phone authentication for SMS OTP

2. **Cloud Firestore**
   - Go to Firestore Database
   - Click "Create database"
   - Start in **test mode** (for development)
   - Choose location: **europe-west** (closest to Rwanda)

3. **Cloud Storage**
   - Go to Storage
   - Click "Get Started"
   - Start in **test mode**

4. **Cloud Messaging** (FCM)
   - Already enabled by default

5. **Analytics**
   - Already enabled by default

### Step 4: Set Up Firestore Security Rules

Go to Firestore → Rules and replace with the security rules from the technical specification document.

### Step 5: Create Firestore Indexes

Create the following composite indexes in Firestore:

**cooperatives collection:**
- Fields: `district` (Ascending), `availableForSale` (Ascending)
- Fields: `expectedHarvestDate` (Ascending), `availableForSale` (Ascending)

**orders collection:**
- Fields: `buyerId` (Ascending), `status` (Ascending)
- Fields: `sellerId` (Ascending), `status` (Ascending)

## 🚀 Running the Application

### Prerequisites
- Flutter SDK installed
- Android Studio or VS Code
- Android device or emulator
- Firebase project created

### Steps to Run

1. **Download google-services.json** (see Firebase Setup above)

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

## 📱 Testing the App

### Test User Flow:
1. App starts with splash screen
2. Select language (English or Kinyarwanda)
3. Select user type (e.g., Farmer Cooperative)
4. Register with email and password
5. Login with credentials
6. View dashboard (basic UI)

### Test Accounts
Create test accounts for each user type:
- Seed Producer
- Agro-Dealer
- Farmer Cooperative
- Aggregator
- Institution (School/Hospital)

## 🔧 Next Development Steps

### Phase 1 (Remaining):
- [ ] Add phone number authentication with OTP
- [ ] Implement profile completion screens for each user type
- [ ] Add image upload functionality
- [ ] Implement form validation helpers

### Phase 2: User-Specific Features
- [ ] Farmer dashboard and planting registration
- [ ] Aggregator search and ordering system
- [ ] Institution requirements and bidding
- [ ] Agro-dealer inventory management
- [ ] Seed producer distribution tracking

### Phase 3: Advanced Features
- [ ] SMS integration (Africa's Talking)
- [ ] Google Maps integration
- [ ] Traceability visualization
- [ ] Push notifications
- [ ] Offline support
- [ ] PDF generation for receipts

## 📝 Important Notes

### Current Status
- ✅ Basic app structure complete
- ✅ Authentication flow ready
- ✅ Firebase configured (awaiting google-services.json)
- ⏳ User-specific features pending
- ⏳ SMS integration pending

### Known Limitations
- Dashboard is a placeholder
- User profiles are minimal
- No SMS functionality yet
- No image upload yet
- Maps not integrated

### Security Reminders
- Never commit `google-services.json` to public repos
- Use environment variables for API keys
- Implement proper Firestore security rules
- Enable App Check before production

## 🆘 Troubleshooting

### Firebase initialization error
**Solution:** Make sure `google-services.json` is in `android/app/` directory

### Build failed
**Solution:** Run `flutter clean` then `flutter pub get`

### Dependencies conflict
**Solution:** Run `flutter pub upgrade`

### Hot reload not working
**Solution:** Restart the app completely

## 📚 Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Provider Documentation](https://pub.dev/packages/provider)
- [Material Design 3](https://m3.material.io/)

## 👥 Development Team Notes

### Code Style
- Use `const` constructors where possible
- Follow Flutter naming conventions
- Add comments for complex logic
- Keep widgets small and focused

### Git Workflow
1. Create feature branches
2. Make small, focused commits
3. Write descriptive commit messages
4. Test before pushing

### Testing Strategy
- Unit tests for business logic
- Widget tests for UI components
- Integration tests for user flows

---

**Version:** 1.0.0  
**Last Updated:** October 30, 2025  
**Status:** Development Phase 1
