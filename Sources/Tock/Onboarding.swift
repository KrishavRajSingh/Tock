import SwiftUI

struct OnboardingView: View {
    @ObservedObject var model: AppModel
    let close: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Tock plays a sound when you click.")
                .font(.title2.weight(.semibold))
            Text("Tock listens for mouse clicks and scrolling. It never sees what you click on. Keyboard sounds are off until you turn them on, and even then Tock only notices that a key went down or up, never which key.")
            Text("Pick a sound and set the volume from the Tock icon in the menu bar.")

            if model.listening {
                HStack {
                    Spacer()
                    Button("Got it", action: close)
                        .keyboardShortcut(.defaultAction)
                }
            } else {
                Text("macOS is stopping Tock from seeing mouse clicks. Allow Tock under Privacy & Security → Input Monitoring, then come back to this window.")
                    .foregroundStyle(.secondary)
                HStack {
                    Spacer()
                    Button("Open System Settings", action: model.openInputMonitoringSettings)
                        .keyboardShortcut(.defaultAction)
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(24)
        .frame(width: 400)
    }
}

@MainActor
final class OnboardingWindow {
    private var window: NSWindow?

    func show(model: AppModel) {
        if window == nil {
            let view = OnboardingView(model: model) { [weak self] in
                self?.window?.close()
            }
            let window = NSWindow(contentViewController: NSHostingController(rootView: view))
            window.title = "Welcome to Tock"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.center()
            self.window = window
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
