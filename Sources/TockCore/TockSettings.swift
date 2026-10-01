/// User settings. The initialiser takes raw stored values and repairs
/// anything missing or out of range.
public struct TockSettings: Equatable, Sendable {
    public static let defaultVolume = 0.6

    public var enabled: Bool
    public var soundID: String
    public var volume: Double
    public var releaseSoundEnabled: Bool
    public var scrollSoundEnabled: Bool
    public var keySoundEnabled: Bool

    public init(
        enabled: Bool? = nil, soundID: String? = nil, volume: Double? = nil,
        releaseSoundEnabled: Bool? = nil, scrollSoundEnabled: Bool? = nil, keySoundEnabled: Bool? = nil
    ) {
        self.enabled = enabled ?? true
        self.soundID = SoundLibrary.sound(id: soundID ?? "").id
        if let volume, volume.isFinite {
            self.volume = min(max(volume, 0), 1)
        } else {
            self.volume = Self.defaultVolume
        }
        self.releaseSoundEnabled = releaseSoundEnabled ?? true
        self.scrollSoundEnabled = scrollSoundEnabled ?? false
        self.keySoundEnabled = keySoundEnabled ?? false
    }
}
