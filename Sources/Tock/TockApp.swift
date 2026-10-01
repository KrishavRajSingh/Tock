import SwiftUI

@main
struct TockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        MenuBarExtra("Tock", systemImage: "cursorarrow.click.2") {
            MenuPanel(model: delegate.model)
        }
        .menuBarExtraStyle(.window)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private static let welcomeKey = "hasSeenWelcome"

    let model = AppModel()
    private let onboarding = OnboardingWindow()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Also set by LSUIElement in the bundle; this covers `swift run`.
        NSApp.setActivationPolicy(.accessory)
        model.start()

        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: Self.welcomeKey) || !model.listening {
            onboarding.show(model: model)
            defaults.set(true, forKey: Self.welcomeKey)
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        model.refresh()
    }
}
