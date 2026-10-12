import ApplicationServices
import AppKit

enum AccessibilityPermission {
    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    /// Prompts once via the system trust dialog when possible.
    @discardableResult
    static func requestTrust() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    static func openSystemSettings() {
        let urls = [
            URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"),
            URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility"),
            URL(string: "x-apple.systempreferences:com.apple.preference.security")
        ]
        for url in urls.compactMap({ $0 }) {
            if NSWorkspace.shared.open(url) {
                return
            }
        }
    }
}
