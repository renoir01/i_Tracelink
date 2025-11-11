#!/bin/bash

# 🔨 iTraceLink APK Build Script
# Run this on your LOCAL MACHINE where Flutter is installed

set -e  # Exit on any error

echo "================================================"
echo "🚀 iTraceLink APK Build Script"
echo "================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if Flutter is installed
echo -e "${BLUE}[1/7]${NC} Checking Flutter installation..."
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter is not installed or not in PATH${NC}"
    echo ""
    echo "Please install Flutter from: https://flutter.dev/docs/get-started/install"
    exit 1
fi

FLUTTER_VERSION=$(flutter --version | head -n 1)
echo -e "${GREEN}✅ Flutter found: $FLUTTER_VERSION${NC}"
echo ""

# Check Flutter doctor
echo -e "${BLUE}[2/7]${NC} Running Flutter doctor..."
flutter doctor
echo ""

# Check Firebase configuration
echo -e "${BLUE}[3/7]${NC} Checking Firebase configuration..."
if [ ! -f "android/app/google-services.json" ]; then
    echo -e "${RED}❌ Firebase configuration missing!${NC}"
    echo ""
    echo "You need to download google-services.json from Firebase Console:"
    echo "1. Go to: https://console.firebase.google.com"
    echo "2. Select 'i-tracelink' project"
    echo "3. Go to Project Settings"
    echo "4. Download google-services.json"
    echo "5. Place it in: android/app/google-services.json"
    echo ""
    exit 1
fi
echo -e "${GREEN}✅ Firebase configuration found${NC}"
echo ""

# Clean previous builds
echo -e "${BLUE}[4/7]${NC} Cleaning previous builds..."
flutter clean
echo -e "${GREEN}✅ Clean complete${NC}"
echo ""

# Get dependencies
echo -e "${BLUE}[5/7]${NC} Getting dependencies..."
flutter pub get
echo -e "${GREEN}✅ Dependencies installed${NC}"
echo ""

# Build APK
echo -e "${BLUE}[6/7]${NC} Building release APK..."
echo -e "${YELLOW}⏳ This will take 5-10 minutes...${NC}"
echo ""

flutter build apk --release

echo ""
echo -e "${GREEN}✅ APK built successfully!${NC}"
echo ""

# Show APK location and size
echo -e "${BLUE}[7/7]${NC} APK Information:"
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"

if [ -f "$APK_PATH" ]; then
    APK_SIZE=$(ls -lh "$APK_PATH" | awk '{print $5}')
    echo -e "${GREEN}📱 Location: $APK_PATH${NC}"
    echo -e "${GREEN}📦 Size: $APK_SIZE${NC}"
    echo ""

    # Create submission folder
    SUBMISSION_DIR="$HOME/Desktop/iTraceLink_Submission"
    mkdir -p "$SUBMISSION_DIR"

    # Copy APK with better name
    cp "$APK_PATH" "$SUBMISSION_DIR/iTraceLink-v1.0.apk"
    echo -e "${GREEN}✅ APK copied to: $SUBMISSION_DIR/iTraceLink-v1.0.apk${NC}"
    echo ""
else
    echo -e "${RED}❌ APK not found at expected location${NC}"
    exit 1
fi

echo "================================================"
echo -e "${GREEN}🎉 BUILD COMPLETE!${NC}"
echo "================================================"
echo ""
echo "Next steps:"
echo "1. Transfer APK to your Android phone"
echo "2. Install and test the app"
echo "3. Record 5-minute demo video (see VIDEO_DEMONSTRATION_SCRIPT.md)"
echo "4. Upload video and APK to cloud storage"
echo "5. Update SUBMISSION_README.md with links"
echo "6. Follow BUILD_AND_SUBMIT_CHECKLIST.md"
echo ""
echo -e "${BLUE}📱 APK Location:${NC} $SUBMISSION_DIR/iTraceLink-v1.0.apk"
echo ""
echo "Good luck with your submission! 🚀"
