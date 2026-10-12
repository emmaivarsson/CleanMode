import ApplicationServices
import Foundation

enum InputLockError: Error {
    case accessibilityDenied
    case tapCreationFailed
}

/// Installs a session event tap that swallows keyboard and pointer events while
/// Clean Mode is active. Option-key hold progress is tracked for unlock.
final class InputLockService {
    var onUnlockHoldProgress: ((Double) -> Void)?
    var onUnlockRequested: (() -> Void)?
    var onTapFailed: (() -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var optionHoldStart: Date?
    private var progressTimer: Timer?
    private(set) var isActive = false

    func start() throws {
        guard AccessibilityPermission.isTrusted else {
            throw InputLockError.accessibilityDenied
        }
        stop()

        let mask = Self.eventMask
        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            guard let refcon else { return Unmanaged.passUnretained(event) }
            let service = Unmanaged<InputLockService>.fromOpaque(refcon).takeUnretainedValue()
            return service.handle(proxy: proxy, type: type, event: event)
        }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            throw InputLockError.tapCreationFailed
        }

        eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        isActive = true
    }

    func stop() {
        progressTimer?.invalidate()
        progressTimer = nil
        optionHoldStart = nil

        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        isActive = false
    }

    private static var eventMask: CGEventMask {
        let types: [CGEventType] = [
            .keyDown, .keyUp, .flagsChanged,
            .leftMouseDown, .leftMouseUp, .leftMouseDragged,
            .rightMouseDown, .rightMouseUp, .rightMouseDragged,
            .otherMouseDown, .otherMouseUp, .otherMouseDragged,
            .mouseMoved, .scrollWheel, .tabletPointer, .tabletProximity
        ]
        return types.reduce(CGEventMask(0)) { partial, type in
            partial | (CGEventMask(1) << type.rawValue)
        }
    }

    private func handle(proxy _: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.onTapFailed?()
                }
            }
            return Unmanaged.passUnretained(event)
        }

        guard isActive else {
            return Unmanaged.passUnretained(event)
        }

        if type == .flagsChanged {
            updateOptionHold(from: event)
            // Swallow flags so Option alone cannot affect other apps mid-clean.
            return nil
        }

        // Swallow all other keyboard and pointer events.
        if type == .keyDown || type == .keyUp {
            // If Option is no longer held (e.g. weird edge), keep lock.
            return nil
        }

        return nil
    }

    private func updateOptionHold(from event: CGEvent) {
        let flags = event.flags
        let optionDown = flags.contains(.maskAlternate)
        // Require Option without Command/Control/Shift so wiping other modifiers
        // cannot accidentally count toward unlock.
        let onlyOption =
            optionDown
            && !flags.contains(.maskCommand)
            && !flags.contains(.maskControl)
            && !flags.contains(.maskShift)

        if onlyOption {
            if optionHoldStart == nil {
                optionHoldStart = Date()
                startProgressTimer()
            }
        } else {
            resetHold()
        }
    }

    private func startProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.tickHoldProgress()
        }
        RunLoop.main.add(progressTimer!, forMode: .common)
        tickHoldProgress()
    }

    private func tickHoldProgress() {
        guard let start = optionHoldStart else {
            resetHold()
            return
        }
        let elapsed = Date().timeIntervalSince(start)
        let progress = min(1, elapsed / CleanModeConstants.unlockHoldDuration)
        DispatchQueue.main.async { [weak self] in
            self?.onUnlockHoldProgress?(progress)
        }
        if elapsed >= CleanModeConstants.unlockHoldDuration {
            resetHold()
            DispatchQueue.main.async { [weak self] in
                self?.onUnlockRequested?()
            }
        }
    }

    private func resetHold() {
        progressTimer?.invalidate()
        progressTimer = nil
        optionHoldStart = nil
        DispatchQueue.main.async { [weak self] in
            self?.onUnlockHoldProgress?(0)
        }
    }
}
