import Foundation

/// Amplitude over time: a linear rise for `attack` seconds, then an
/// exponential fall with time constant `decay` seconds.
public struct Envelope: Equatable, Sendable {
    public var attack: Double
    public var decay: Double

    public init(attack: Double = 0, decay: Double) {
        self.attack = attack
        self.decay = decay
    }

    func amplitude(at time: Double) -> Double {
        if time < attack { return time / attack }
        guard decay > 0 else { return 0 }
        return exp(-(time - attack) / decay)
    }
}

/// One component of a sound.
public struct Layer: Equatable, Sendable {
    public enum Source: Equatable, Sendable {
        case noise
        case sine(Double)
        case triangle(Double)

        /// The same source with its frequency multiplied by `ratio`.
        public func scaled(by ratio: Double) -> Source {
            switch self {
            case .noise: return .noise
            case .sine(let frequency): return .sine(frequency * ratio)
            case .triangle(let frequency): return .triangle(frequency * ratio)
            }
        }
    }

    public struct Filter: Equatable, Sendable {
        public enum Kind: Equatable, Sendable {
            case lowpass, bandpass, highpass
        }

        public var kind: Kind
        public var frequency: Double
        public var q: Double

        public init(kind: Kind, frequency: Double, q: Double) {
            self.kind = kind
            self.frequency = frequency
            self.q = q
        }

        public static func lowpass(_ frequency: Double, q: Double = 0.707) -> Filter {
            Filter(kind: .lowpass, frequency: frequency, q: q)
        }

        public static func bandpass(_ frequency: Double, q: Double = 1) -> Filter {
            Filter(kind: .bandpass, frequency: frequency, q: q)
        }

        public static func highpass(_ frequency: Double, q: Double = 0.707) -> Filter {
            Filter(kind: .highpass, frequency: frequency, q: q)
        }
    }

    public var source: Source
    public var envelope: Envelope
    public var gain: Double
    public var filter: Filter?
    /// Tone frequency glides from its start value to `start × pitchEnd`.
    public var pitchEnd: Double
    /// Seconds after the start of the sound at which this layer begins.
    public var delay: Double

    public init(
        source: Source, envelope: Envelope, gain: Double,
        filter: Filter? = nil, pitchEnd: Double = 1, delay: Double = 0
    ) {
        self.source = source
        self.envelope = envelope
        self.gain = gain
        self.filter = filter
        self.pitchEnd = pitchEnd
        self.delay = delay
    }

    public static func noise(
        gain: Double, attack: Double = 0, decay: Double, filter: Filter? = nil, delay: Double = 0
    ) -> Layer {
        Layer(source: .noise, envelope: Envelope(attack: attack, decay: decay), gain: gain, filter: filter, delay: delay)
    }

    public static func sine(
        _ frequency: Double, gain: Double, attack: Double = 0.0005, decay: Double,
        pitchEnd: Double = 1, delay: Double = 0
    ) -> Layer {
        Layer(
            source: .sine(frequency), envelope: Envelope(attack: attack, decay: decay), gain: gain,
            pitchEnd: pitchEnd, delay: delay)
    }

    public static func triangle(
        _ frequency: Double, gain: Double, attack: Double = 0.0005, decay: Double,
        pitchEnd: Double = 1, delay: Double = 0
    ) -> Layer {
        Layer(
            source: .triangle(frequency), envelope: Envelope(attack: attack, decay: decay), gain: gain,
            pitchEnd: pitchEnd, delay: delay)
    }
}

/// A complete description of one sound. `gain` is the peak level of the
/// rendered output, 0...1.
public struct SoundRecipe: Equatable, Sendable {
    public var layers: [Layer]
    public var duration: Double
    public var gain: Double
    public var seed: UInt64

    public init(layers: [Layer], duration: Double, gain: Double, seed: UInt64) {
        self.layers = layers
        self.duration = duration
        self.gain = gain
        self.seed = seed
    }
}
