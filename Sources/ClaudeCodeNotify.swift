import Cocoa
import UserNotifications

// MARK: - Notification Categories
let kCategoryPermission = "PERMISSION_PROMPT"
let kCategoryIdle = "IDLE_PROMPT"
let kActionOpen = "OPEN_TERMINAL"

// MARK: - Configuration
let kDefaultTerminalBundleID = "dev.warp.Warp-Stable"

func terminalBundleID() -> String {
    let args = CommandLine.arguments
    if let idx = args.firstIndex(of: "--terminal"), idx + 1 < args.count {
        return args[idx + 1]
    }
    return ProcessInfo.processInfo.environment["CLAUDE_NOTIFY_TERMINAL"] ?? kDefaultTerminalBundleID
}

// MARK: - Delegate
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler handler: @escaping (UNNotificationPresentationOptions) -> Void) {
        handler([.banner, .sound, .list])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler handler: @escaping () -> Void) {
        activateTerminal()
        handler()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { NSApp.terminate(nil) }
    }

    private func activateTerminal() {
        let bundleID = terminalBundleID()
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration()) { _, _ in }
        }
    }
}

// MARK: - Main
let app = NSApplication.shared
let delegate = NotificationDelegate()
let center = UNUserNotificationCenter.current()
center.delegate = delegate

// Register action categories
let action = UNNotificationAction(identifier: kActionOpen, title: "Open Terminal", options: .foreground)
center.setNotificationCategories([
    UNNotificationCategory(identifier: kCategoryPermission, actions: [action], intentIdentifiers: []),
    UNNotificationCategory(identifier: kCategoryIdle, actions: [action], intentIdentifiers: [])
])

// Parse arguments
let args = CommandLine.arguments
let body     = args.count > 1 ? args[1] : "Claude Code needs your attention"
let subtitle = args.count > 2 ? args[2] : ""
let sound    = args.count > 3 ? args[3] : "Glass"
let category = args.count > 4 ? args[4] : kCategoryIdle

// Send notification
let content = UNMutableNotificationContent()
content.title = "Claude Code"
if !subtitle.isEmpty { content.subtitle = subtitle }
content.body = body
content.categoryIdentifier = category
content.sound = UNNotificationSound(named: UNNotificationSoundName(sound))
content.interruptionLevel = .timeSensitive

center.add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)) { error in
    if let error = error { print("Error: \(error.localizedDescription)"); exit(1) }
}

// Stay alive to handle notification clicks, auto-exit after 2 minutes
DispatchQueue.main.asyncAfter(deadline: .now() + 120) { NSApp.terminate(nil) }
app.run()
