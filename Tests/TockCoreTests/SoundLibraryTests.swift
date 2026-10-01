import Testing
@testable import TockCore

@Suite struct SoundLibraryTests {
    @Test func hasSixteenSoundsFourPerFamily() {
        #expect(SoundLibrary.sounds.count == 16)
        #expect(SoundFamily.allCases.count == 4)
        for family in SoundFamily.allCases {
            #expect(SoundLibrary.sounds(in: family).count == 4)
        }
    }

    @Test func idsAndNamesAreUnique() {
        #expect(Set(SoundLibrary.sounds.map(\.id)).count == 16)
        #expect(Set(SoundLibrary.sounds.map(\.name)).count == 16)
    }

    @Test func mechanicalFamilyHasTheFourSwitches() {
        #expect(SoundLibrary.sounds(in: .mechanical).map(\.id) == [
            "mechanical.blue", "mechanical.brown", "mechanical.red", "mechanical.thock",
        ])
    }

    @Test func defaultSoundIsFirstDeskSound() {
        #expect(SoundLibrary.defaultSound == SoundLibrary.sounds(in: .desk)[0])
    }

    @Test func lookupFallsBackToDefaultForUnknownID() {
        #expect(SoundLibrary.sound(id: "analog.zap").id == "analog.zap")
        #expect(SoundLibrary.sound(id: "removed.sound") == SoundLibrary.defaultSound)
        #expect(SoundLibrary.sound(id: "") == SoundLibrary.defaultSound)
    }

    @Test func releaseIsShorterAndQuieterThanPress() {
        for sound in SoundLibrary.sounds {
            #expect(sound.release.duration < sound.press.duration, "\(sound.id)")
            #expect(sound.release.gain < sound.press.gain, "\(sound.id)")
            #expect(!sound.release.layers.isEmpty, "\(sound.id)")
        }
    }

    @Test func scrollTickIsShorterAndQuieterThanRelease() {
        for sound in SoundLibrary.sounds {
            #expect(sound.scroll.duration < sound.release.duration, "\(sound.id)")
            #expect(sound.scroll.gain < sound.release.gain, "\(sound.id)")
            #expect(!sound.scroll.layers.isEmpty, "\(sound.id)")
        }
    }

    @Test func keySoundIsShorterAndQuieterThanPress() {
        for sound in SoundLibrary.sounds {
            #expect(sound.key.duration < sound.press.duration, "\(sound.id)")
            #expect(sound.key.gain < sound.press.gain, "\(sound.id)")
            #expect(sound.key.gain > sound.release.gain, "\(sound.id)")
            #expect(!sound.key.layers.isEmpty, "\(sound.id)")
        }
    }

    @Test func fivePitchVariantsWithinThreePercent() {
        #expect(SoundLibrary.pitchVariants.count == 5)
        #expect(SoundLibrary.pitchVariants.contains(1.0))
        #expect(SoundLibrary.pitchVariants.allSatisfy { $0 >= 0.97 && $0 <= 1.03 })
    }

    @Test func pressSoundsAreShort() {
        for sound in SoundLibrary.sounds {
            #expect(sound.press.duration <= 0.25, "\(sound.id)")
        }
    }

    @Test func everyRenderIsSafeAndAudible() {
        for sound in SoundLibrary.sounds {
            for (phase, recipe) in [("press", sound.press), ("release", sound.release), ("scroll", sound.scroll), ("key", sound.key)] {
                for shift in SoundLibrary.pitchVariants {
                    let samples = Synth.render(recipe, pitchShift: shift)
                    let label = "\(sound.id) \(phase) ×\(shift)"
                    let peak = samples.reduce(Float(0)) { max($0, abs($1)) }
                    #expect(!samples.isEmpty, "\(label)")
                    #expect(samples.allSatisfy { $0.isFinite }, "\(label)")
                    #expect(peak <= 1, "\(label)")
                    #expect(peak > 0.05, "\(label)")
                    #expect(samples.first == 0, "\(label)")
                    #expect(samples.last == 0, "\(label)")
                }
            }
        }
    }
}
