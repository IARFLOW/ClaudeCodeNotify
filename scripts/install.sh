#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$(cd "$SCRIPT_DIR/.." && pwd)/build"
APP_BUNDLE="ClaudeCodeNotify.app"

# Build first
bash "$SCRIPT_DIR/build.sh"

# Install
echo ""
echo "Installing to /Applications..."
rm -rf "/Applications/$APP_BUNDLE"
cp -R "$BUILD_DIR/$APP_BUNDLE" "/Applications/$APP_BUNDLE"

# Register
/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -f "/Applications/$APP_BUNDLE" 2>/dev/null || true

echo "Installed at /Applications/$APP_BUNDLE"
echo ""

# First run to trigger notification permission
echo "Launching first run to request notification permissions..."
echo "Please ALLOW notifications when macOS prompts you."
echo ""
open -a /Applications/$APP_BUNDLE --args "Setup complete" "ClaudeCodeNotify" "Glass" "IDLE_PROMPT"

echo "Done! Now configure your Claude Code hooks (see README.md)."
