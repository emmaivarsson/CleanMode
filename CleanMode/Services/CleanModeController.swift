import AppKit
import SwiftUI

@MainActor
final class CleanModeController: ObservableObject {
    enum State: Equatable {
        case idle
        case locked
        case needsPermission
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var optionHoldProgress: Double = 0
    @Published private(set) var hasSeenFirstRunTip = UserDefaults.standard.bool(forKey: "hasSeenFirstRunTip")

    private let inputLock = InputLockService()
    private let overlay = OverlayWindowController()
    private var autoUnlockTimer: Timer?
    private var sleepObservers: [NSObjectProtocol] = []

    var isLocked: Bool { state == .locked }

    var menuBarSymbolName: String {
        switch state {
        case .idle:
            return "drop"
        case .locked:
            return "drop.fill"
        case .needsPermission:
            return "exclamationmark.triangle"
        }
    }

    var menuBarTint: Color {
        switch state {
        case .idle:
            return Color(nsColor: .labelColor)
        case .locked:
            return Color(red: 0.22, green: 0.55, blue: 0.55) // muted teal
        case .needsPermission:
            return Color(nsColor: .systemOrange)
        }
    }

    init() {
        inputLock.onUnlockHoldProgress = { [weak self] progress in
            Task { @MainActor in
                guard let self else { return }
                self.optionHoldProgress = progress
                self.overlay.updateHoldProgress(progress)
            }
        }
        inputLock.onUnlockRequested = { [weak self] in
            Task { @MainActor in
                self?.stopCleanMode(reason: .unlockHold)
            }
        }
        inputLock.onTapFailed = { [weak self] in
            Task { @MainActor in
                self?.failOpen(reason: .tapFailed)
            }
        }

        refreshPermissionState()
        installSleepObservers()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillTerminate),
            name: NSApplication.willTerminateNotification,
            object: nil
        )
    }

    deinit {
        sleepObservers.forEach { NotificationCenter.default.removeObserver($0) }
        NotificationCenter.default.removeObserver(self)
    }

    func refreshPermissionState() {
        if AccessibilityPermission.isTrusted {
            if state == .needsPermission {
                state = .idle
            }
        } else if !isLocked {
            state = .needsPermission
        }
    }

    func startCleanMode() {
        refreshPermissionState()
        guard AccessibilityPermission.isTrusted else {
            state = .needsPermission
            AccessibilityPermission.requestTrust()
            return
        }

        guard !isLocked else { return }

        do {
            try inputLock.start()
        } catch {
            state = .needsPermission
            AccessibilityPermission.openSystemSettings()
            return
        }

        state = .locked
        optionHoldProgress = 0
        overlay.show()
        scheduleAutoUnlock()
        markFirstRunTipSeen()
    }

    func stopCleanMode(reason: StopReason = .manual) {
        guard isLocked || inputLock.isActive else {
            refreshPermissionState()
            return
        }
        failOpen(reason: reason)
    }

    func openAccessibilitySettings() {
        AccessibilityPermission.openSystemSettings()
    }

    func markFirstRunTipSeen() {
        hasSeenFirstRunTip = true
        UserDefaults.standard.set(true, forKey: "hasSeenFirstRunTip")
    }

    enum StopReason {
        case manual
        case unlockHold
        case timeout
        case sleep
        case terminate
        case tapFailed
    }

    private func failOpen(reason: StopReason) {
        autoUnlockTimer?.invalidate()
        autoUnlockTimer = nil
        inputLock.stop()
        overlay.hide()
        optionHoldProgress = 0
        state = AccessibilityPermission.isTrusted ? .idle : .needsPermission
        _ = reason // retained for clarity / future logging
    }

    private func scheduleAutoUnlock() {
        autoUnlockTimer?.invalidate()
        autoUnlockTimer = Timer.scheduledTimer(
            withTimeInterval: CleanModeConstants.autoUnlockTimeout,
            repeats: false
        ) { [weak self] _ in
            Task { @MainActor in
                self?.stopCleanMode(reason: .timeout)
            }
        }
    }

    private func installSleepObservers() {
        let workspace = NSWorkspace.shared.notificationCenter
        let names: [NSNotification.Name] = [
            NSWorkspace.willSleepNotification,
            NSWorkspace.screensDidSleepNotification,
            NSWorkspace.didWakeNotification,
            NSWorkspace.screensDidWakeNotification
        ]
        for name in names {
            let token = workspace.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in
                    self?.stopCleanMode(reason: .sleep)
                }
            }
            sleepObservers.append(token)
        }
    }

    @objc private func applicationWillTerminate() {
        stopCleanMode(reason: .terminate)
    }
}
