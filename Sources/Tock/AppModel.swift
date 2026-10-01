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
            if settings.keySoundEnabled != oldValue.keySoundEnabled {
                updateKeyMonitor(askForPermission: true)
            }
        }
    }

    @Published private(set) var audioRunning = false
    @Published private(set) var listening = false
    @Published private(set) var launchAtLogin = false
    @Published private(set) var launchAtLoginError: String?
    /// True when key sounds are on but macOS has not allowed Tock to listen.
    @Published private(set) var keyPermissionNeeded = false

    private let monitor = ClickMonitor()
    private let keyMonitor = KeyMonitor()
    private let player = AudioPlayer()
    private var scrollTicker = ScrollTicker()

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
        keyMonitor.handler = { [weak self] phase in
            self?.handleKey(phase)
        }
        monitor.scrollHandler = { [weak self] distance, precise in
            self?.handleScroll(distance: distance, precise: precise)
        }
        player.volume = Float(settings.volume)
        for target in SoundTarget.allCases {
            player.load(SoundLibrary.sound(id: settings.soundID(for: target)), for: target)
        }
        refresh()
    }

    /// Retries anything that is not working and re-reads system state.
    func refresh() {
        player.start()
        monitor.start()
        listening = monitor.isListening
        updateKeyMonitor(askForPermission: false)
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    /// Makes `sound` the current sound for `target` and plays it once.
    func select(_ sound: Sound, for target: SoundTarget) {
        if sound.id == settings.soundID(for: target) {
            player.play(.press, for: target)
            return
        }
        settings.setSoundID(sound.id, for: target)
        player.load(sound, for: target) { [weak self] in
            self?.player.play(.press, for: target)
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

    /// Registers this build with macOS for Input Monitoring, then opens the
    /// settings pane. Registering matters after an update: macOS ties a grant
    /// to the exact build, so an old "on" switch does not cover a new build.
    func requestKeyPermission() {
        keyMonitor.requestPermission()
        openInputMonitoringSettings()
    }

    func openInputMonitoringSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")!
        NSWorkspace.shared.open(url)
    }

    private func handleClick(_ phase: ClickPhase) {
        guard settings.enabled else { return }
        if phase == .release, !settings.releaseSoundEnabled { return }
        player.play(phase, for: .mouse)
    }

    private func handleKey(_ phase: ClickPhase) {
        guard settings.enabled, settings.keySoundEnabled else { return }
        if phase == .release, !settings.releaseSoundEnabled { return }
        player.play(phase, for: .keyboard)
    }

    /// Starts or stops key listening to match the setting. The system
    /// permission prompt is only raised when the user has just turned key
    /// sounds on, never on launch.
    private func updateKeyMonitor(askForPermission: Bool) {
        guard settings.keySoundEnabled else {
            keyMonitor.stop()
            keyPermissionNeeded = false
            return
        }
        if askForPermission, !keyMonitor.hasPermission {
            keyMonitor.requestPermission()
        }
        keyMonitor.start()
        keyPermissionNeeded = !keyMonitor.isListening
    }

    private func handleScroll(distance: Double, precise: Bool) {
        guard settings.enabled, settings.scrollSoundEnabled else { return }
        let now = ProcessInfo.processInfo.systemUptime
        if scrollTicker.shouldTick(delta: distance, precise: precise, time: now) {
            player.playScrollTick()
        }
    }
}
