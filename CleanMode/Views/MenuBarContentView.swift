import AppKit
import SwiftUI

struct MenuBarContentView: View {
    @EnvironmentObject private var controller: CleanModeController

    var body: some View {
        Group {
            if controller.isLocked {
                Text("Clean Mode is on")
                Text("Hold ⌥ for 5 seconds to exit")
                Divider()
                Button("Stop Clean Mode") {
                    controller.stopCleanMode(reason: .manual)
                }
                .keyboardShortcut(".", modifiers: [.command])
            } else {
                Button("Start Clean Mode") {
                    controller.startCleanMode()
                }
                .keyboardShortcut("s")

                if controller.state == .needsPermission {
                    Divider()
                    Text("Accessibility required")
                    if let message = controller.lastErrorMessage {
                        Text(message)
                    } else {
                        Text("If the toggle is already ON: Quit & Relaunch")
                    }
                    Button("Open Accessibility Settings…") {
                        controller.openAccessibilitySettings()
                    }
                    Button("Quit & Relaunch") {
                        controller.relaunchAfterGrantingAccess()
                    }
                } else if !controller.hasSeenFirstRunTip {
                    Divider()
                    Text("Tip: Hold ⌥ for 5 seconds to exit")
                }
            }

            Divider()
            Button("Quit Clean Mode") {
                controller.stopCleanMode(reason: .terminate)
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .onAppear {
            controller.refreshPermissionState()
        }
    }
}
