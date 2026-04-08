# ClaudeCodeNotify

Native macOS notification system for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Get notified when Claude finishes a task or needs your permission — click the notification to jump straight back to your terminal.

![macOS](https://img.shields.io/badge/macOS-26%2B-blue) ![Swift](https://img.shields.io/badge/Swift-6.2-orange) ![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Native macOS notifications** via `UNUserNotificationCenter` — no third-party dependencies
- **Click-to-focus**: clicking a notification activates your terminal window with full keyboard focus
- **Differentiated alerts**: distinct sounds and messages for "task complete" vs "permission needed"
- **Smart suppression**: skips permission notifications when your terminal is already focused
- **Claude icon**: notifications display the Claude app icon
- **Daemon mode**: runs persistently in the background, watching a trigger file — no process spawning per notification
- **Terminal agnostic**: works with Warp, iTerm2, Kitty, Alacritty, Terminal.app, or any terminal
- **Lightweight**: compiled Swift binary, background daemon with zero CPU when idle

## Requirements

- macOS 14+ (tested on macOS 26 Tahoe)
- Swift compiler (`swiftc`) — included with Xcode Command Line Tools
- [Claude.app](https://claude.ai/download) installed (for the notification icon)
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI

## Quick Install

```bash
git clone https://github.com/IARFLOW/ClaudeCodeNotify.git
cd ClaudeCodeNotify
bash scripts/install.sh
```

When macOS asks to allow notifications, click **Allow**.

## How It Works

ClaudeCodeNotify runs as a **background daemon** that watches the file `~/.claude/notify-trigger`. Claude Code hooks write notification data to this file, and the daemon picks it up instantly, sends the notification, and clears the file.

The trigger file format is:

```
message|subtitle|sound|category
```

For example: `Finished and waiting|Done|Glass.aiff|IDLE_PROMPT`

When you click a notification, it activates your terminal with full keyboard focus — no mouse click needed.

## Configure Claude Code Hooks

Add the following to your `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "permission_prompt",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Needs your permission to continue|Action Required|Basso.aiff|PERMISSION_PROMPT' > ~/.claude/notify-trigger"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Finished and waiting for your response|Done|Glass.aiff|STOP' > ~/.claude/notify-trigger"
          }
        ]
      }
    ]
  }
}
```

> **Note:** The `Stop` hook fires every time Claude finishes responding. The `Notification` hook with `permission_prompt` matcher fires when Claude needs your approval to proceed.

### For other terminals

Set the `CLAUDE_NOTIFY_TERMINAL` environment variable to your terminal's bundle identifier:

```bash
# Add to your ~/.zshrc or ~/.bashrc
export CLAUDE_NOTIFY_TERMINAL="com.googlecode.iterm2"
```

<details>
<summary>Common terminal bundle identifiers</summary>

| Terminal | Bundle ID |
|----------|-----------|
| Warp | `dev.warp.Warp-Stable` |
| iTerm2 | `com.googlecode.iterm2` |
| Terminal.app | `com.apple.Terminal` |
| Kitty | `net.kovidgoyal.kitty` |
| Alacritty | `org.alacritty` |
| Ghostty | `com.mitchellh.ghostty` |
| Hyper | `co.zeit.hyper` |

To find any app's bundle ID:

```bash
defaults read /Applications/YourTerminal.app/Contents/Info.plist CFBundleIdentifier
```

</details>

### Available macOS sounds

`Basso`, `Blow`, `Bottle`, `Frog`, `Funk`, `Glass`, `Hero`, `Morse`, `Ping`, `Pop`, `Purr`, `Sosumi`, `Submarine`, `Tink`

## Auto-start with LaunchAgent

To keep the daemon running automatically, create `~/Library/LaunchAgents/com.iarflow.claudecodenotify.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.iarflow.claudecodenotify</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Applications/ClaudeCodeNotify.app/Contents/MacOS/ClaudeCodeNotify</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
```

Then load it:

```bash
launchctl load ~/Library/LaunchAgents/com.iarflow.claudecodenotify.plist
```

## Tips

### Make notifications persist until dismissed

By default, macOS banners disappear after a few seconds. To make them stay:

1. Open **System Settings** > **Notifications**
2. Find **Claude Code** in the app list
3. Change notification style from **Banners** to **Alerts**

## Troubleshooting

### Notifications appear but clicking them does nothing

If click-to-focus stops activating your terminal even though notifications are still being delivered, macOS's internal notification router (`usernoted`) may have a stale delegate reference. Reset it with:

```bash
killall usernoted
```

`usernoted` respawns automatically in under a second with no data loss. This is a generic macOS fix, not specific to ClaudeCodeNotify — it's worth knowing for any notification-based app.

### Notifications don't appear at all

1. Check the daemon is running:

   ```bash
   pgrep -fl ClaudeCodeNotify
   ```

   There should be **exactly one** process. If there are zero, load the LaunchAgent. If there are more than one, something went wrong with install — run `pkill -f ClaudeCodeNotify` and reinstall.

2. Test the daemon directly, bypassing Claude Code hooks:

   ```bash
   echo 'Test|From terminal|Glass.aiff|IDLE_PROMPT' > ~/.claude/notify-trigger
   ```

   Run this from an app **other** than your terminal (otherwise the built-in focus suppression kicks in). If you get a notification, the daemon is healthy and the issue is in your hook configuration.

3. Verify the app has notification permission in **System Settings → Notifications → Claude Code**.

## Uninstall

```bash
launchctl unload ~/Library/LaunchAgents/com.iarflow.claudecodenotify.plist
rm ~/Library/LaunchAgents/com.iarflow.claudecodenotify.plist
rm -rf /Applications/ClaudeCodeNotify.app
```

Then remove the `hooks` section from `~/.claude/settings.json`.

## License

MIT
