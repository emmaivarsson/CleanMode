import AppKit
import SwiftUI

@MainActor
final class OverlayWindowController {
    private var windows: [NSWindow] = []
    private var hostingControllers: [NSHostingController<OverlayView>] = []

    func show() {
        hide()
        for screen in NSScreen.screens {
            let window = OverlayNSWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            window.setFrame(screen.frame, display: true)
            window.isOpaque = false
            window.backgroundColor = .clear
            window.level = .screenSaver
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
            window.ignoresMouseEvents = true
            window.hasShadow = false
            window.isReleasedWhenClosed = false

            let hosting = NSHostingController(rootView: OverlayView(holdProgress: 0))
            hosting.view.frame = CGRect(origin: .zero, size: screen.frame.size)
            window.contentViewController = hosting
            window.alphaValue = 0
            window.orderFrontRegardless()
            windows.append(window)
            hostingControllers.append(hosting)

            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.25
                window.animator().alphaValue = 1
            }
        }
    }

    func updateHoldProgress(_ progress: Double) {
        for hosting in hostingControllers {
            hosting.rootView = OverlayView(holdProgress: progress)
        }
    }

    func hide() {
        let existing = windows
        windows = []
        hostingControllers = []
        for window in existing {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.2
                window.animator().alphaValue = 0
            }, completionHandler: {
                window.orderOut(nil)
                window.contentViewController = nil
            })
        }
    }
}

private final class OverlayNSWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
