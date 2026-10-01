import SwiftUI

@main
struct TockApp: App {
    var body: some Scene {
        MenuBarExtra("Tock", systemImage: "cursorarrow.click.2") {
            Button("Quit Tock") { NSApplication.shared.terminate(nil) }
        }
    }
}
