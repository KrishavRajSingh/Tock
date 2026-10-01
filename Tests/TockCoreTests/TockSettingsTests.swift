import Testing
@testable import TockCore

@Suite struct TockSettingsTests {
    @Test func defaults() {
        let settings = TockSettings()
        #expect(settings.enabled)
        #expect(settings.soundID == SoundLibrary.sounds(in: .desk)[0].id)
        #expect(settings.volume == 0.6)
        #expect(settings.releaseSoundEnabled)
        #expect(!settings.scrollSoundEnabled)
        #expect(!settings.keySoundEnabled)
    }

    @Test func storedKeySettingIsKept() {
        #expect(TockSettings(keySoundEnabled: true).keySoundEnabled)
    }

    @Test func storedScrollSettingIsKept() {
        #expect(TockSettings(scrollSoundEnabled: true).scrollSoundEnabled)
    }

    @Test func storedValuesAreKept() {
        let settings = TockSettings(enabled: false, soundID: "toybox.pop", volume: 0.25, releaseSoundEnabled: false)
        #expect(!settings.enabled)
        #expect(settings.soundID == "toybox.pop")
        #expect(settings.volume == 0.25)
        #expect(!settings.releaseSoundEnabled)
    }

    @Test func unknownSoundIDFallsBackToDefault() {
        #expect(TockSettings(soundID: "removed.sound").soundID == SoundLibrary.defaultSound.id)
    }

    @Test func keySoundFollowsMouseSoundUntilChosen() {
        #expect(TockSettings().keySoundID == SoundLibrary.defaultSound.id)
        #expect(TockSettings(soundID: "toybox.pop").keySoundID == "toybox.pop")
    }

    @Test func storedKeySoundIsKeptSeparateFromMouseSound() {
        let settings = TockSettings(soundID: "toybox.pop", keySoundID: "analog.tick")
        #expect(settings.soundID == "toybox.pop")
        #expect(settings.keySoundID == "analog.tick")
    }

    @Test func unknownKeySoundIDFallsBackToDefault() {
        let settings = TockSettings(soundID: "toybox.pop", keySoundID: "removed.sound")
        #expect(settings.keySoundID == SoundLibrary.defaultSound.id)
    }

    @Test func soundIDIsReadAndWrittenPerTarget() {
        var settings = TockSettings(soundID: "toybox.pop", keySoundID: "analog.tick")
        #expect(settings.soundID(for: .mouse) == "toybox.pop")
        #expect(settings.soundID(for: .keyboard) == "analog.tick")
        settings.setSoundID("desk.wood", for: .keyboard)
        #expect(settings.keySoundID == "desk.wood")
        #expect(settings.soundID == "toybox.pop")
        settings.setSoundID("analog.zap", for: .mouse)
        #expect(settings.soundID == "analog.zap")
        #expect(settings.keySoundID == "desk.wood")
    }

    @Test func volumeIsClampedAndNonFiniteFallsBack() {
        #expect(TockSettings(volume: 7).volume == 1)
        #expect(TockSettings(volume: -1).volume == 0)
        #expect(TockSettings(volume: .nan).volume == 0.6)
        #expect(TockSettings(volume: .infinity).volume == 0.6)
    }
}
