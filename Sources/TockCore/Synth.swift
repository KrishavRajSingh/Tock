import Foundation

public enum Synth {
    static let maxDuration = 2.0
    static let maxSampleRate = 384_000.0
    static let fadeInSeconds = 0.0003
    static let fadeOutSeconds = 0.004

    /// Renders `recipe` to mono samples in -1...1. Pure: the same arguments
    /// always give the same samples.
    public static func render(
        _ recipe: SoundRecipe, sampleRate: Double = 48_000, pitchShift: Double = 1
    ) -> [Float] {
        guard sampleRate.isFinite, sampleRate > 0, recipe.duration.isFinite, recipe.duration > 0 else {
            return []
        }
        let rate = min(sampleRate, maxSampleRate)
        let count = Int((min(recipe.duration, maxDuration) * rate).rounded())
        guard count > 0 else { return [] }
        let shift = pitchShift.isFinite && pitchShift > 0 ? pitchShift : 1

        var mix = [Double](repeating: 0, count: count)
        for (index, layer) in recipe.layers.enumerated() {
            add(layer, index: index, seed: recipe.seed, shift: shift, sampleRate: rate, to: &mix)
        }
        applyFades(to: &mix, sampleRate: rate)
        return normalised(mix, peak: recipe.gain)
    }

    private static func add(
        _ layer: Layer, index: Int, seed: UInt64, shift: Double, sampleRate: Double, to mix: inout [Double]
    ) {
        let delay = layer.delay.isFinite ? min(max(layer.delay, 0), maxDuration) : 0
        let start = Int((delay * sampleRate).rounded())
        guard start < mix.count else { return }

        var random = SplitMix64(seed: seed &+ UInt64(index) &* 0x9E37_79B9_7F4A_7C15)
        var filter = layer.filter.map { Biquad($0, shift: shift, sampleRate: sampleRate) }
        let glideTime = max(layer.envelope.decay, 0.0001)
        let nyquistLimit = sampleRate * 0.45
        var phase = 0.0

        for i in start..<mix.count {
            let time = Double(i - start) / sampleRate
            var sample: Double
            switch layer.source {
            case .noise:
                sample = random.nextUnit()
            case .sine(let base), .triangle(let base):
                let glide = layer.pitchEnd + (1 - layer.pitchEnd) * exp(-time / glideTime)
                let frequency = min(max(base * shift * glide, 0), nyquistLimit)
                if case .sine = layer.source {
                    sample = sin(2 * .pi * phase)
                } else {
                    let x = phase + 0.25
                    sample = 4 * abs(x - (x + 0.5).rounded(.down)) - 1
                }
                phase += frequency / sampleRate
                phase -= phase.rounded(.down)
            }
            if filter != nil { sample = filter!.process(sample) }
            mix[i] += sample * layer.envelope.amplitude(at: time) * layer.gain
        }
    }

    private static func applyFades(to mix: inout [Double], sampleRate: Double) {
        let count = mix.count
        let fadeIn = min(count, max(1, Int(fadeInSeconds * sampleRate)))
        let fadeOut = min(count, max(1, Int(fadeOutSeconds * sampleRate)))
        for i in 0..<fadeIn { mix[i] *= Double(i) / Double(fadeIn) }
        for i in 0..<fadeOut { mix[count - 1 - i] *= Double(i) / Double(fadeOut) }
    }

    private static func normalised(_ mix: [Double], peak target: Double) -> [Float] {
        let cleaned = mix.map { $0.isFinite ? $0 : 0 }
        let peak = cleaned.reduce(0) { max($0, abs($1)) }
        let level = target.isFinite ? min(max(target, 0), 1) : 0
        guard peak > 0 else { return [Float](repeating: 0, count: mix.count) }
        let scale = level / peak
        return cleaned.map { Float($0 * scale) }
    }
}

/// Second-order filter (RBJ cookbook coefficients, transposed direct form II).
struct Biquad {
    private var b0 = 0.0, b1 = 0.0, b2 = 0.0, a1 = 0.0, a2 = 0.0
    private var z1 = 0.0, z2 = 0.0

    init(_ filter: Layer.Filter, shift: Double, sampleRate: Double) {
        let requested = filter.frequency.isFinite ? filter.frequency * shift : 1000
        let frequency = min(max(requested, 20), sampleRate * 0.45)
        let q = filter.q.isFinite ? max(filter.q, 0.1) : 0.707
        let omega = 2 * Double.pi * frequency / sampleRate
        let alpha = sin(omega) / (2 * q)
        let cosine = cos(omega)
        let a0 = 1 + alpha

        switch filter.kind {
        case .lowpass:
            b0 = (1 - cosine) / 2
            b1 = 1 - cosine
            b2 = (1 - cosine) / 2
        case .highpass:
            b0 = (1 + cosine) / 2
            b1 = -(1 + cosine)
            b2 = (1 + cosine) / 2
        case .bandpass:
            b0 = alpha
            b1 = 0
            b2 = -alpha
        }
        b0 /= a0
        b1 /= a0
        b2 /= a0
        a1 = -2 * cosine / a0
        a2 = (1 - alpha) / a0
    }

    mutating func process(_ input: Double) -> Double {
        let output = b0 * input + z1
        z1 = b1 * input - a1 * output + z2
        z2 = b2 * input - a2 * output
        return output
    }
}
