import SwiftUI

@main
struct TockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        MenuBarExtra("Tock", systemImage: "cursorarrow.click.2") {
            MenuPanel(model: delegate.model, openWindow: delegate.showMainWindow)
        }
        .menuBarExtraStyle(.window)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private static let welcomeKey = "hasSeenWelcome"

    let model = AppModel()
    private let mainWindow = MainWindow()
    private let onboarding = OnboardingWindow()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // The bundle is a regular app already; this covers `swift run`.
        NSApp.setActivationPolicy(.regular)
        model.start()

        // Starting at login should be silent: no window in the user's face.
        if !Self.launchedAsLoginItem {
            showMainWindow()
        }

        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: Self.welcomeKey) || !model.listening {
            onboarding.show(model: model)
            defaults.set(true, forKey: Self.welcomeKey)
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        model.refresh()
    }

    /// Clicking the Dock icon, or opening Tock again while it is running.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showMainWindow()
        return false
    }

    /// Closing the window leaves Tock sounding from the menu bar.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func showMainWindow() {
        mainWindow.show(model: model)
    }

    private static var launchedAsLoginItem: Bool {
        guard let event = NSAppleEventManager.shared().currentAppleEvent,
              event.eventID == kAEOpenApplication else { return false }
        return event.paramDescriptor(forKeyword: keyAEPropData)?.enumCodeValue == keyAELaunchedAsLogInItem
    }
}
