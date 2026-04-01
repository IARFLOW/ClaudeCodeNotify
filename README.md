# ClaudeCodeNotify

Native macOS notification system for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Get notified when Claude finishes a task or needs your permission — click the notification to jump straight back to your terminal.

![macOS](https://img.shields.io/badge/macOS-26%2B-blue) ![Swift](https://img.shields.io/badge/Swift-6.2-orange) ![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Native macOS notifications** via `UNUserNotificationCenter` — no third-party dependencies
- **Click-to-focus**: clicking a notification activates your terminal window
- **Differentiated alerts**: distinct sounds and messages for "task complete" vs "permission needed"
- **Claude icon**: notifications display the Claude app icon
- **Action button**: "Open Terminal" button for quick access
- **Terminal agnostic**: works with Warp, iTerm2, Kitty, Alacritty, Terminal.app, or any terminal
- **Lightweight**: compiled Swift binary, runs in the background, auto-exits after 2 minutes

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

## Configure Claude Code Hooks

Add the following to your `~/.claude/settings.json`:

### For Warp

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "permission_prompt",
        "hooks": [
          {
            "type": "command",
            "command": "/Applications/ClaudeCodeNotify.app/Contents/MacOS/ClaudeCodeNotify 'Needs your permission to continue' 'Action Required' 'Basso' 'PERMISSION_PROMPT' &"
          }
        ]
      },
      {
        "matcher": "idle_prompt",
        "hooks": [
          {
            "type": "command",
            "command": "/Applications/ClaudeCodeNotify.app/Contents/MacOS/ClaudeCodeNotify 'Finished and waiting for your response' 'Done' 'Glass' 'IDLE_PROMPT' &"
          }
        ]
      }
    ]
  }
}
```

### For other terminals

Set the `--terminal` flag or the `CLAUDE_NOTIFY_TERMINAL` environment variable to your terminal's bundle identifier:

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "idle_prompt",
        "hooks": [
          {
            "type": "command",
            "command": "/Applications/ClaudeCodeNotify.app/Contents/MacOS/ClaudeCodeNotify 'Finished and waiting for your response' 'Done' 'Glass' 'IDLE_PROMPT' --terminal com.googlecode.iterm2 &"
          }
        ]
      }
    ]
  }
}
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

## Usage

```
ClaudeCodeNotify <message> [subtitle] [sound] [category] [--terminal <bundle_id>]
```

| Argument | Description | Default |
|----------|-------------|---------|
| `message` | Notification body text | `"Claude Code needs your attention"` |
| `subtitle` | Notification subtitle | *(empty)* |
| `sound` | macOS sound name | `Glass` |
| `category` | `IDLE_PROMPT` or `PERMISSION_PROMPT` | `IDLE_PROMPT` |
| `--terminal` | Terminal app bundle ID | `dev.warp.Warp-Stable` |

### Available macOS sounds

`Basso`, `Blow`, `Bottle`, `Frog`, `Funk`, `Glass`, `Hero`, `Morse`, `Ping`, `Pop`, `Purr`, `Sosumi`, `Submarine`, `Tink`

## Tips

### Make notifications persist until dismissed

By default, macOS banners disappear after a few seconds. To make them stay:

1. Open **System Settings** > **Notifications**
2. Find **Claude Code** in the app list
3. Change notification style from **Banners** to **Alerts**

### Environment variable

Instead of using `--terminal`, you can set the terminal globally:

```bash
# Add to your ~/.zshrc or ~/.bashrc
export CLAUDE_NOTIFY_TERMINAL="com.googlecode.iterm2"
```

## How It Works

ClaudeCodeNotify is a minimal native macOS app built with Swift. It uses Apple's `UNUserNotificationCenter` API to deliver notifications and handle user interactions.

When Claude Code triggers a hook event (task complete or permission needed), it launches the binary directly. The app sends the notification and stays alive briefly to handle clicks. When you click the notification or the "Open Terminal" action button, it activates your terminal app and exits.

The app runs as a background process (`LSUIElement`) — it won't appear in your Dock or app switcher.

## Uninstall

```bash
rm -rf /Applications/ClaudeCodeNotify.app
```

Then remove the `hooks` section from `~/.claude/settings.json`.

## License

MIT
