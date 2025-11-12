@echo off
REM 🔨 iTraceLink APK Build Script (Windows)
REM Run this on your LOCAL MACHINE where Flutter is installed

echo ================================================
echo 🚀 iTraceLink APK Build Script (Windows)
echo ================================================
echo.

REM Check if Flutter is installed
echo [1/7] Checking Flutter installation...
where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Flutter is not installed or not in PATH
    echo.
    echo Please install Flutter from: https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)

flutter --version | findstr /C:"Flutter"
echo ✅ Flutter found
echo.

REM Check Flutter doctor
echo [2/7] Running Flutter doctor...
flutter doctor
echo.

REM Check Firebase configuration
echo [3/7] Checking Firebase configuration...
if not exist "android\app\google-services.json" (
    echo ❌ Firebase configuration missing!
    echo.
    echo You need to download google-services.json from Firebase Console:
    echo 1. Go to: https://console.firebase.google.com
    echo 2. Select 'i-tracelink' project
    echo 3. Go to Project Settings
    echo 4. Download google-services.json
    echo 5. Place it in: android\app\google-services.json
    echo.
    pause
    exit /b 1
)
echo ✅ Firebase configuration found
echo.

REM Clean previous builds
echo [4/7] Cleaning previous builds...
call flutter clean
echo ✅ Clean complete
echo.

REM Get dependencies
echo [5/7] Getting dependencies...
call flutter pub get
echo ✅ Dependencies installed
echo.

REM Build APK
echo [6/7] Building release APK...
echo ⏳ This will take 5-10 minutes...
echo.

call flutter build apk --release

echo.
echo ✅ APK built successfully!
echo.

REM Show APK location
echo [7/7] APK Information:
set APK_PATH=build\app\outputs\flutter-apk\app-release.apk

if exist "%APK_PATH%" (
    echo 📱 Location: %APK_PATH%
    for %%A in ("%APK_PATH%") do echo 📦 Size: %%~zA bytes
    echo.

    REM Create submission folder
    set SUBMISSION_DIR=%USERPROFILE%\Desktop\iTraceLink_Submission
    if not exist "%SUBMISSION_DIR%" mkdir "%SUBMISSION_DIR%"

    REM Copy APK with better name
    copy /Y "%APK_PATH%" "%SUBMISSION_DIR%\iTraceLink-v1.0.apk"
    echo ✅ APK copied to: %SUBMISSION_DIR%\iTraceLink-v1.0.apk
    echo.
) else (
    echo ❌ APK not found at expected location
    pause
    exit /b 1
)

echo ================================================
echo 🎉 BUILD COMPLETE!
echo ================================================
echo.
echo Next steps:
echo 1. Transfer APK to your Android phone
echo 2. Install and test the app
echo 3. Record 5-minute demo video (see VIDEO_DEMONSTRATION_SCRIPT.md)
echo 4. Upload video and APK to cloud storage
echo 5. Update SUBMISSION_README.md with links
echo 6. Follow BUILD_AND_SUBMIT_CHECKLIST.md
echo.
echo 📱 APK Location: %SUBMISSION_DIR%\iTraceLink-v1.0.apk
echo.
echo Good luck with your submission! 🚀
echo.
pause
