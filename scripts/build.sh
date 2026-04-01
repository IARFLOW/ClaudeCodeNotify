#!/bin/bash
set -e

APP_NAME="ClaudeCodeNotify"
APP_BUNDLE="$APP_NAME.app"
BUILD_DIR="$(cd "$(dirname "$0")/.." && pwd)/build"
SRC_DIR="$(cd "$(dirname "$0")/.." && pwd)/Sources"
RES_DIR="$(cd "$(dirname "$0")/.." && pwd)/Resources"

echo "Building $APP_NAME..."

# Create app bundle structure
rm -rf "$BUILD_DIR/$APP_BUNDLE"
mkdir -p "$BUILD_DIR/$APP_BUNDLE/Contents/MacOS"
mkdir -p "$BUILD_DIR/$APP_BUNDLE/Contents/Resources"

# Copy Info.plist
cp "$RES_DIR/Info.plist" "$BUILD_DIR/$APP_BUNDLE/Contents/"

# Extract Claude icon (if Claude.app is installed)
CLAUDE_ICON="/Applications/Claude.app/Contents/Resources/electron.icns"
if [ -f "$CLAUDE_ICON" ]; then
    echo "Found Claude.app — extracting icon..."
    cp "$CLAUDE_ICON" "$BUILD_DIR/$APP_BUNDLE/Contents/Resources/AppIcon.icns"
else
    echo "Warning: Claude.app not found at /Applications/Claude.app"
    echo "The app will work but notifications won't show the Claude icon."
    echo "You can manually place an AppIcon.icns in $APP_BUNDLE/Contents/Resources/"
fi

# Compile
echo "Compiling..."
swiftc -O \
    "$SRC_DIR/$APP_NAME.swift" \
    -o "$BUILD_DIR/$APP_BUNDLE/Contents/MacOS/$APP_NAME" \
    -framework Cocoa \
    -framework UserNotifications

# Sign
echo "Signing..."
codesign --force --sign - "$BUILD_DIR/$APP_BUNDLE"

# Register with LaunchServices
/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -f "$BUILD_DIR/$APP_BUNDLE" 2>/dev/null || true

echo ""
echo "Build successful: $BUILD_DIR/$APP_BUNDLE"
echo ""
echo "To install, run:"
echo "  cp -R $BUILD_DIR/$APP_BUNDLE /Applications/"
