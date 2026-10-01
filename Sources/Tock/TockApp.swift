import SwiftUI

@main
struct TockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        MenuBarExtra("Tock", systemImage: "cursorarrow.click.2") {
            Button("Quit Tock") { NSApplication.shared.terminate(nil) }
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = AppModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Also set by LSUIElement in the bundle; this covers `swift run`.
        NSApp.setActivationPolicy(.accessory)
        model.start()
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        model.refresh()
    }
}
