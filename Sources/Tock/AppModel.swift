import AppKit
import ServiceManagement
import TockCore

/// Owns the settings and connects click capture to audio playback.
@MainActor
final class AppModel: ObservableObject {
    @Published var settings: TockSettings {
        didSet {
            guard settings != oldValue else { return }
            settings.save()
            player.volume = Float(settings.volume)
        }
    }

    @Published private(set) var audioRunning = false
    @Published private(set) var listening = false
    @Published private(set) var launchAtLogin = false
    @Published private(set) var launchAtLoginError: String?

    private let monitor = ClickMonitor()
    private let player = AudioPlayer()

    init() {
        settings = TockSettings.load()
    }

    func start() {
        player.onRunningChange = { [weak self] running in
            self?.audioRunning = running
        }
        monitor.handler = { [weak self] _, phase in
            self?.handleClick(phase)
        }
        player.volume = Float(settings.volume)
        player.load(SoundLibrary.sound(id: settings.soundID))
        refresh()
    }

    /// Retries anything that is not working and re-reads system state.
    func refresh() {
        player.start()
        monitor.start()
        listening = monitor.isListening
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    /// Makes `sound` the current sound and plays it once.
    func select(_ sound: Sound) {
        if sound.id == settings.soundID {
            player.play(.press)
            return
        }
        settings.soundID = sound.id
        player.load(sound) { [weak self] in
            self?.player.play(.press)
        }
    }

    func setLaunchAtLogin(_ on: Bool) {
        do {
            if on {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            launchAtLoginError = nil
        } catch {
            launchAtLoginError = "Couldn't change this. Open Tock from Tock.app, not from a terminal."
        }
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    func openInputMonitoringSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")!
        NSWorkspace.shared.open(url)
    }

    private func handleClick(_ phase: ClickPhase) {
        guard settings.enabled else { return }
        if phase == .release, !settings.releaseSoundEnabled { return }
        player.play(phase)
    }
}
