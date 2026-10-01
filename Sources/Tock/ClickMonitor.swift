import AppKit
import TockCore

/// Reports mouse button presses and releases anywhere on screen. Uses an
/// NSEvent global monitor, which needs no permission for mouse buttons and
/// does not see events sent to Tock's own windows.
final class ClickMonitor {
    var handler: ((MouseButton, ClickPhase) -> Void)?

    private var monitor: Any?

    var isListening: Bool { monitor != nil }

    func start() {
        guard monitor == nil else { return }
        let mask: NSEvent.EventTypeMask = [
            .leftMouseDown, .leftMouseUp,
            .rightMouseDown, .rightMouseUp,
            .otherMouseDown, .otherMouseUp,
        ]
        monitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] event in
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
