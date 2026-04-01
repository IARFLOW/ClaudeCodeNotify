#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$(cd "$SCRIPT_DIR/.." && pwd)/build"
APP_BUNDLE="ClaudeCodeNotify.app"
PLIST_LABEL="com.iarflow.claudecodenotify"
PLIST_PATH="$HOME/Library/LaunchAgents/$PLIST_LABEL.plist"

# Build first
bash "$SCRIPT_DIR/build.sh"

# Stop existing daemon if running
launchctl unload "$PLIST_PATH" 2>/dev/null || true
pkill -f "ClaudeCodeNotify" 2>/dev/null || true

# Install
echo ""
echo "Installing to /Applications..."
rm -rf "/Applications/$APP_BUNDLE"
cp -R "$BUILD_DIR/$APP_BUNDLE" "/Applications/$APP_BUNDLE"

# Register with LaunchServices
/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -f "/Applications/$APP_BUNDLE" 2>/dev/null || true

echo "Installed at /Applications/$APP_BUNDLE"

# First run to request notification permissions
echo ""
echo "Requesting notification permissions..."
echo "Please ALLOW notifications when macOS prompts you."
/Applications/$APP_BUNDLE/Contents/MacOS/ClaudeCodeNotify --setup

# Create LaunchAgent
echo ""
echo "Creating LaunchAgent..."
mkdir -p "$HOME/Library/LaunchAgents"
cat > "$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$PLIST_LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Applications/$APP_BUNDLE/Contents/MacOS/ClaudeCodeNotify</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
EOF

launchctl load "$PLIST_PATH"
echo "Daemon started and will auto-launch on login."

# Create trigger file
touch "$HOME/.claude/notify-trigger" 2>/dev/null || true

echo ""
echo "Done! Now configure your Claude Code hooks (see README.md)."
