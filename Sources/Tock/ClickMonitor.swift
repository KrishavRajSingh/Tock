import AppKit
import TockCore

/// Reports mouse button presses and releases, and scrolling, anywhere on
/// screen. Uses an NSEvent global monitor, which needs no permission for
/// mouse events and does not see events sent to Tock's own windows.
final class ClickMonitor {
    var handler: ((MouseButton, ClickPhase) -> Void)?
    /// Called with the distance of one scroll event and whether it is in
    /// points (trackpad) rather than wheel notches.
    var scrollHandler: ((Double, Bool) -> Void)?

    private var monitor: Any?

    var isListening: Bool { monitor != nil }

    func start() {
        guard monitor == nil else { return }
        let mask: NSEvent.EventTypeMask = [
            .leftMouseDown, .leftMouseUp,
            .rightMouseDown, .rightMouseUp,
            .otherMouseDown, .otherMouseUp,
            .scrollWheel,
        ]
        monitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] event in
            // buttonNumber is only valid on button events, so handle scroll first.
            if event.type == .scrollWheel {
                let distance = abs(event.scrollingDeltaX) + abs(event.scrollingDeltaY)
                self?.scrollHandler?(Double(distance), event.hasPreciseScrollingDeltas)
                return
            }
            guard let button = MouseButton(buttonNumber: event.buttonNumber) else { return }
            switch event.type {
            case .leftMouseDown, .rightMouseDown, .otherMouseDown:
                self?.handler?(button, .press)
            case .leftMouseUp, .rightMouseUp, .otherMouseUp:
                self?.handler?(button, .release)
            default:
                break
            }
        }
    }

    func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }

    deinit { stop() }
}
