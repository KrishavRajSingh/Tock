import CoreGraphics
import TockCore

/// Reports key presses and releases anywhere on screen, using a listen-only
/// event tap. This needs the Input Monitoring permission. Only the event type
/// and the repeat flag are read; the key code and characters never are.
final class KeyMonitor {
    var handler: ((ClickPhase) -> Void)?

    private var tap: CFMachPort?
    private var source: CFRunLoopSource?

    var hasPermission: Bool { CGPreflightListenEventAccess() }

    var isListening: Bool {
        guard let tap else { return false }
        return CGEvent.tapIsEnabled(tap: tap)
    }

    /// Asks macOS to show its Input Monitoring prompt. macOS shows it once;
    /// later calls do nothing visible.
    func requestPermission() {
        _ = CGRequestListenEventAccess()
    }

    /// Starts listening if permission has been granted. Safe to call repeatedly.
    func start() {
        guard hasPermission else { return }
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: true)
            return
        }
        let mask = CGEventMask(1) << CGEventType.keyDown.rawValue | CGEventMask(1) << CGEventType.keyUp.rawValue
        guard
            let tap = CGEvent.tapCreate(
                tap: .cgSessionEventTap, place: .headInsertEventTap, options: .listenOnly,
                eventsOfInterest: mask, callback: keyTapCallback,
                userInfo: Unmanaged.passUnretained(self).toOpaque())
        else { return }
        let source = CFMachPortCreateRunLoopSource(nil, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        self.tap = tap
        self.source = source
    }

    func stop() {
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
        }
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        tap = nil
        source = nil
    }

    deinit { stop() }

    fileprivate func handle(type: CGEventType, event: CGEvent) {
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            // macOS turns a tap off if it thinks it is slow; turn it back on.
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
        case .keyDown, .keyUp:
            let autorepeat = event.getIntegerValueField(.keyboardEventAutorepeat) != 0
            if let phase = KeyStroke.phase(keyDown: type == .keyDown, autorepeat: autorepeat) {
                handler?(phase)
            }
        default:
            break
        }
    }
}

private let keyTapCallback: CGEventTapCallBack = { _, type, event, userInfo in
    if let userInfo {
        Unmanaged<KeyMonitor>.fromOpaque(userInfo).takeUnretainedValue().handle(type: type, event: event)
    }
    return Unmanaged.passUnretained(event)
}
