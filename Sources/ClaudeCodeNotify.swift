import Cocoa
import UserNotifications

// MARK: - Configuration
let kDefaultTerminalBundleID = "dev.warp.Warp-Stable"
let kTriggerFile = NSString("~/.claude/notify-trigger").expandingTildeInPath

func terminalBundleID() -> String {
    ProcessInfo.processInfo.environment["CLAUDE_NOTIFY_TERMINAL"] ?? kDefaultTerminalBundleID
}

// MARK: - Notification Delegate
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler handler: @escaping (UNNotificationPresentationOptions) -> Void) {
        handler([.banner, .sound, .list])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler handler: @escaping () -> Void) {
        let bundleID = terminalBundleID()
        if let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first {
            app.activate()
        } else if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration()) { _, _ in }
        }
        handler()
    }
}

// MARK: - File Watcher
class TriggerWatcher {
    let path: String
    var source: DispatchSourceFileSystemObject?

    init(path: String) {
        self.path = path
    }

    func start() {
        if !FileManager.default.fileExists(atPath: path) {
            FileManager.default.createFile(atPath: path, contents: nil)
        }
        watch()
    }

    private func watch() {
        let fd = open(path, O_EVTONLY)
        guard fd >= 0 else { return }

        source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .attrib],
            queue: .main
        )

        source?.setEventHandler { [weak self] in
            self?.onTrigger()
        }

        source?.setCancelHandler {
            close(fd)
        }

        source?.resume()
    }

    private func onTrigger() {
        guard let data = FileManager.default.contents(atPath: path),
              let text = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else { return }

        // Parse: message|subtitle|sound|category
        let parts = text.components(separatedBy: "|")
        let body     = parts.count > 0 ? parts[0] : "Claude Code needs your attention"
        let subtitle = parts.count > 1 ? parts[1] : ""
        let sound    = parts.count > 2 ? parts[2] : "Glass"
        let category = parts.count > 3 ? parts[3] : "IDLE_PROMPT"

        // Skip all notifications if terminal is focused
        if let frontApp = NSWorkspace.shared.frontmostApplication,
           frontApp.bundleIdentifier == terminalBundleID() {
            clearAndRewatch()
            return
        }

        sendNotification(body: body, subtitle: subtitle, sound: sound, category: category)
        clearAndRewatch()
    }

    private func clearAndRewatch() {
        try? "".write(toFile: path, atomically: true, encoding: .utf8)
        source?.cancel()
        watch()
    }

    private func sendNotification(body: String, subtitle: String, sound: String, category: String) {
        let content = UNMutableNotificationContent()
        content.title = "Claude Code"
        if !subtitle.isEmpty { content.subtitle = subtitle }
        content.body = body
        content.categoryIdentifier = category
        content.sound = UNNotificationSound(named: UNNotificationSoundName(sound))

        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        )
    }
}

// MARK: - One-shot mode (first run / permission request)
if CommandLine.arguments.count > 1 && CommandLine.arguments[1] == "--setup" {
    let app = NSApplication.shared
    let center = UNUserNotificationCenter.current()
    let delegate = NotificationDelegate()
    center.delegate = delegate

    center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
        print(granted ? "Permission granted" : "Permission not granted (will attempt anyway): \(error?.localizedDescription ?? "unknown")")
        // Send a test notification regardless — this registers the app in System Settings
        let content = UNMutableNotificationContent()
        content.title = "Claude Code"
        content.body = granted ? "Notifications are set up and ready!" : "Please enable notifications in System Settings → Notifications → ClaudeCodeNotify"
        content.sound = .default
        center.add(UNNotificationRequest(identifier: "setup", content: content, trigger: nil)) { err in
            if let err = err { print("Notification error: \(err)") }
            else { print("Notification request sent") }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { NSApp.terminate(nil) }
        }
    }
    app.run()

} else {
    // MARK: - Daemon mode
    let app = NSApplication.shared
    let delegate = NotificationDelegate()
    let center = UNUserNotificationCenter.current()
    center.delegate = delegate

    // Register action categories
    let action = UNNotificationAction(identifier: "OPEN_TERMINAL", title: "Open", options: .foreground)
    center.setNotificationCategories([
        UNNotificationCategory(identifier: "PERMISSION_PROMPT", actions: [action], intentIdentifiers: []),
        UNNotificationCategory(identifier: "IDLE_PROMPT", actions: [action], intentIdentifiers: [])
    ])

    // Start watching trigger file
    let watcher = TriggerWatcher(path: kTriggerFile)
    watcher.start()

    withExtendedLifetime(watcher) {
        app.run()
    }
}
