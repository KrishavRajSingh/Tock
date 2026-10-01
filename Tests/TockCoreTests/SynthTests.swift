import Testing
@testable import TockCore

@Suite struct SynthTests {
    let tone = SoundRecipe(layers: [.sine(440, gain: 1, decay: 0.02)], duration: 0.05, gain: 0.8, seed: 1)
    let noise = SoundRecipe(
        layers: [.noise(gain: 1, decay: 0.01, filter: .bandpass(2000, q: 3))],
        duration: 0.05, gain: 0.5, seed: 1)

    func peak(_ samples: [Float]) -> Float {
        samples.reduce(0) { max($0, abs($1)) }
    }

    @Test func sampleCountMatchesDuration() {
        #expect(Synth.render(tone, sampleRate: 48_000).count == 2400)
        #expect(Synth.render(tone, sampleRate: 44_100).count == 2205)
    }

    @Test func sameInputGivesIdenticalOutput() {
        #expect(Synth.render(noise) == Synth.render(noise))
    }

    @Test func differentSeedChangesNoise() {
        var other = noise
        other.seed = 2
        #expect(Synth.render(noise) != Synth.render(other))
    }

    @Test func startsAndEndsAtSilence() {
        for recipe in [tone, noise] {
            let samples = Synth.render(recipe)
            #expect(samples.first == 0)
            #expect(samples.last == 0)
        }
    }

    @Test func peakEqualsGain() {
        #expect(abs(peak(Synth.render(tone)) - 0.8) < 0.0001)
        #expect(abs(peak(Synth.render(noise)) - 0.5) < 0.0001)
    }

    @Test func gainIsClampedToOne() {
        var loud = tone
        loud.gain = 5
        #expect(peak(Synth.render(loud)) <= 1)
    }

    @Test func pitchShiftKeepsCountAndChangesSound() {
        let base = Synth.render(tone)
        let shifted = Synth.render(tone, pitchShift: 1.03)
        #expect(shifted.count == base.count)
        #expect(shifted != base)
    }

    @Test func invalidPitchShiftIsTreatedAsOne() {
        let base = Synth.render(tone)
        for shift in [0, -1, Double.nan, Double.infinity] {
            #expect(Synth.render(tone, pitchShift: shift) == base)
        }
    }

    @Test func invalidDurationOrSampleRateGivesEmptyOutput() {
        for duration in [0, -1, Double.nan, Double.infinity] {
            var recipe = tone
            recipe.duration = duration
            #expect(Synth.render(recipe).isEmpty)
        }
        for rate in [0, -48_000, Double.nan] {
            #expect(Synth.render(tone, sampleRate: rate).isEmpty)
        }
    }

    @Test func overlongDurationIsCapped() {
        var recipe = tone
        recipe.duration = 1_000_000
        #expect(Synth.render(recipe).count == 96_000)
    }

    @Test func noLayersGivesSilenceOfTheRightLength() {
        let samples = Synth.render(SoundRecipe(layers: [], duration: 0.01, gain: 1, seed: 0))
        #expect(samples.count == 480)
        #expect(samples.allSatisfy { $0 == 0 })
    }

    @Test func hostileLayerValuesStayFinite() {
        let recipe = SoundRecipe(
            layers: [
                .noise(gain: 1, decay: 0.01, filter: .lowpass(90_000, q: 0)),
                .sine(.nan, gain: 1, decay: 0.01),
                .triangle(500_000, gain: .infinity, decay: -1, delay: .nan),
                .sine(440, gain: 1, decay: 0.01, delay: 99),
            ],
            duration: 0.02, gain: 1, seed: 3)
        let samples = Synth.render(recipe)
        #expect(samples.count == 960)
        #expect(samples.allSatisfy { $0.isFinite && abs($0) <= 1 })
    }
}
