import Foundation
import TockCore

extension TockSettings {
    private enum Key {
        static let enabled = "enabled"
        static let soundID = "soundID"
        static let volume = "volume"
        static let releaseSoundEnabled = "releaseSoundEnabled"
        static let scrollSoundEnabled = "scrollSoundEnabled"
        static let keySoundEnabled = "keySoundEnabled"
    }

    static func load(from defaults: UserDefaults = .standard) -> TockSettings {
        TockSettings(
            enabled: defaults.object(forKey: Key.enabled) as? Bool,
            soundID: defaults.string(forKey: Key.soundID),
            volume: defaults.object(forKey: Key.volume) as? Double,
            releaseSoundEnabled: defaults.object(forKey: Key.releaseSoundEnabled) as? Bool,
            scrollSoundEnabled: defaults.object(forKey: Key.scrollSoundEnabled) as? Bool,
            keySoundEnabled: defaults.object(forKey: Key.keySoundEnabled) as? Bool)
    }

    func save(to defaults: UserDefaults = .standard) {
        defaults.set(enabled, forKey: Key.enabled)
        defaults.set(soundID, forKey: Key.soundID)
        defaults.set(volume, forKey: Key.volume)
        defaults.set(releaseSoundEnabled, forKey: Key.releaseSoundEnabled)
        defaults.set(scrollSoundEnabled, forKey: Key.scrollSoundEnabled)
        defaults.set(keySoundEnabled, forKey: Key.keySoundEnabled)
    }
}
