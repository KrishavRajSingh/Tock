/// The families, in the order they are listed.
public enum SoundFamily: String, CaseIterable, Sendable {
    case desk = "Desk"
    case mechanical = "Mechanical"
    case custom = "Custom"
    case vintage = "Vintage"
    case quiet = "Quiet"
    case analog = "Analog"
    case toybox = "Toybox"
}

public struct Sound: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let family: SoundFamily
    public let press: SoundRecipe
    public let release: SoundRecipe
    public let scroll: SoundRecipe
    public let key: SoundRecipe

    /// A sound whose release, scroll tick and key sound are derived from its press.
    init(id: String, name: String, family: SoundFamily, press: SoundRecipe) {
        self.id = id
        self.name = name
        self.family = family
        self.press = press
        self.release = SoundLibrary.release(of: press)
        self.scroll = SoundLibrary.scroll(of: press)
        self.key = SoundLibrary.key(of: press)
    }
}

public enum SoundLibrary {
    /// Each sound is rendered once per variant; one is picked at random per
    /// click so repeated clicks do not sound mechanical.
    public static let pitchVariants: [Double] = [0.97, 0.985, 1.0, 1.015, 1.03]

    public static var defaultSound: Sound { sounds[0] }

    public static func sound(id: String) -> Sound {
        sounds.first { $0.id == id } ?? defaultSound
    }

    public static func sounds(in family: SoundFamily) -> [Sound] {
        sounds.filter { $0.family == family }
    }

    /// The release counterpart of a press: shorter, quieter and a little higher.
    public static func release(of press: SoundRecipe) -> SoundRecipe {
        variant(of: press, time: 0.6, pitch: 1.2, gain: 0.5, seedOffset: 1000)
    }

    /// The scroll tick of a press: much shorter, much quieter and higher.
    public static func scroll(of press: SoundRecipe) -> SoundRecipe {
        variant(of: press, time: 0.35, pitch: 1.5, gain: 0.3, seedOffset: 2000)
    }

    /// The key-press sound of a press: a little shorter, quieter and higher,
    /// since typing is far more frequent than clicking.
    public static func key(of press: SoundRecipe) -> SoundRecipe {
        variant(of: press, time: 0.8, pitch: 1.1, gain: 0.7, seedOffset: 3000)
    }

    /// `press` with its timing, pitch and level scaled.
    private static func variant(
        of press: SoundRecipe, time: Double, pitch: Double, gain: Double, seedOffset: UInt64
    ) -> SoundRecipe {
        var variant = press
        variant.duration = press.duration * time
        variant.gain = press.gain * gain
        variant.seed = press.seed &+ seedOffset
        variant.layers = press.layers.map { layer in
            var layer = layer
            layer.source = layer.source.scaled(by: pitch)
            layer.envelope.decay *= time
            layer.delay *= time
            layer.filter?.frequency *= pitch
            return layer
        }
        return variant
    }

    public static let sounds: [Sound] = [
        // Desk: things you might knock on a desk.
        Sound(id: "desk.tock", name: "Tock", family: .desk, press: SoundRecipe(
            layers: [
                .sine(190, gain: 1.0, decay: 0.022, pitchEnd: 0.7),
                .noise(gain: 0.5, decay: 0.004, filter: .bandpass(1800, q: 2)),
            ],
            duration: 0.09, gain: 0.8, seed: 1)),
        Sound(id: "desk.switch", name: "Switch", family: .desk, press: SoundRecipe(
            layers: [
                .noise(gain: 0.7, decay: 0.003, filter: .highpass(3000)),
                .sine(2400, gain: 0.35, decay: 0.006),
                .sine(320, gain: 0.6, decay: 0.012, pitchEnd: 0.8),
            ],
            duration: 0.06, gain: 0.75, seed: 2)),
        Sound(id: "desk.wood", name: "Wood", family: .desk, press: SoundRecipe(
            layers: [
                .triangle(520, gain: 1.0, decay: 0.02, pitchEnd: 0.85),
                .noise(gain: 0.4, decay: 0.008, filter: .bandpass(900, q: 4)),
            ],
            duration: 0.09, gain: 0.8, seed: 3)),
        Sound(id: "desk.pen", name: "Pen", family: .desk, press: SoundRecipe(
            layers: [
                .noise(gain: 0.8, decay: 0.004, filter: .bandpass(4200, q: 6)),
                .noise(gain: 0.6, decay: 0.004, filter: .bandpass(5200, q: 6), delay: 0.018),
                .sine(700, gain: 0.3, decay: 0.01),
            ],
            duration: 0.06, gain: 0.7, seed: 4)),

        // Analog: plain oscillators, like an old synth.
        Sound(id: "analog.blip", name: "Blip", family: .analog, press: SoundRecipe(
            layers: [
                .sine(880, gain: 1.0, decay: 0.025),
            ],
            duration: 0.09, gain: 0.6, seed: 5)),
        Sound(id: "analog.zap", name: "Zap", family: .analog, press: SoundRecipe(
            layers: [
                .sine(1500, gain: 1.0, decay: 0.03, pitchEnd: 0.25),
            ],
            duration: 0.1, gain: 0.6, seed: 6)),
        Sound(id: "analog.thump", name: "Thump", family: .analog, press: SoundRecipe(
            layers: [
                .sine(150, gain: 1.0, attack: 0.001, decay: 0.045, pitchEnd: 0.45),
                .noise(gain: 0.25, decay: 0.006, filter: .lowpass(700)),
            ],
            duration: 0.16, gain: 0.85, seed: 7)),
        Sound(id: "analog.tick", name: "Tick", family: .analog, press: SoundRecipe(
            layers: [
                .triangle(2200, gain: 0.8, decay: 0.006),
                .noise(gain: 0.5, decay: 0.002, filter: .highpass(6000)),
            ],
            duration: 0.04, gain: 0.6, seed: 8)),

        // Toybox: rising pitches and round tones.
        Sound(id: "toybox.pop", name: "Pop", family: .toybox, press: SoundRecipe(
            layers: [
                .sine(380, gain: 1.0, decay: 0.018, pitchEnd: 2.2),
            ],
            duration: 0.07, gain: 0.75, seed: 9)),
        Sound(id: "toybox.bubble", name: "Bubble", family: .toybox, press: SoundRecipe(
            layers: [
                .sine(520, gain: 1.0, attack: 0.004, decay: 0.03, pitchEnd: 1.9),
            ],
            duration: 0.12, gain: 0.7, seed: 10)),
        Sound(id: "toybox.squeak", name: "Squeak", family: .toybox, press: SoundRecipe(
            layers: [
                .triangle(1300, gain: 1.0, attack: 0.003, decay: 0.025, pitchEnd: 1.5),
                .sine(2600, gain: 0.2, decay: 0.02, pitchEnd: 1.5),
            ],
            duration: 0.1, gain: 0.5, seed: 11)),
        Sound(id: "toybox.marble", name: "Marble", family: .toybox, press: SoundRecipe(
            layers: [
                .sine(1900, gain: 1.0, decay: 0.012),
                .sine(2850, gain: 0.5, decay: 0.008),
                .noise(gain: 0.3, decay: 0.003, filter: .bandpass(2500, q: 3)),
            ],
            duration: 0.07, gain: 0.65, seed: 12)),

        // Mechanical: keyboard switches, named after the usual stem colours.
        // Blue is clicky: the click jacket snaps, then the key bottoms out.
        Sound(id: "mechanical.blue", name: "Blue", family: .mechanical, press: SoundRecipe(
            layers: [
                .noise(gain: 2.0, decay: 0.0012, filter: .highpass(6000)),
                .sine(3400, gain: 0.8, decay: 0.002),
                .noise(gain: 2.5, decay: 0.0025, filter: .bandpass(2800, q: 1.5), delay: 0.011),
                .sine(1500, gain: 0.12, decay: 0.003, delay: 0.011),
                .sine(300, gain: 0.06, decay: 0.008, pitchEnd: 0.85, delay: 0.011),
            ],
            duration: 0.07, gain: 0.7, seed: 13)),
        // Brown is tactile: a soft bump, then a rounder bottom-out.
        Sound(id: "mechanical.brown", name: "Brown", family: .mechanical, press: SoundRecipe(
            layers: [
                .noise(gain: 0.5, decay: 0.0015, filter: .bandpass(3500, q: 2)),
                .noise(gain: 2.5, decay: 0.0025, filter: .bandpass(2200, q: 1.5), delay: 0.006),
                .sine(1900, gain: 0.3, decay: 0.003, delay: 0.006),
                .sine(260, gain: 0.1, decay: 0.008, pitchEnd: 0.8, delay: 0.006),
            ],
            duration: 0.07, gain: 0.75, seed: 14)),
        // Red is linear: nothing until the bottom-out clack.
        Sound(id: "mechanical.red", name: "Red", family: .mechanical, press: SoundRecipe(
            layers: [
                .noise(gain: 3.0, decay: 0.004, filter: .bandpass(1300, q: 1.5)),
                .sine(1250, gain: 0.5, decay: 0.004),
                .noise(gain: 0.8, decay: 0.003, filter: .bandpass(1800, q: 2), delay: 0.005),
                .sine(280, gain: 0.08, decay: 0.008, pitchEnd: 0.8),
            ],
            duration: 0.07, gain: 0.7, seed: 15)),
        // Thock is a lubed switch in a heavy, foam-filled case: low and damped.
        Sound(id: "mechanical.thock", name: "Thock", family: .mechanical, press: SoundRecipe(
            layers: [
                .sine(120, gain: 0.08, decay: 0.012, pitchEnd: 0.85),
                .noise(gain: 4.0, decay: 0.005, filter: .bandpass(600, q: 1.5)),
                .noise(gain: 2.5, decay: 0.0025, filter: .bandpass(2000, q: 1)),
            ],
            duration: 0.09, gain: 0.85, seed: 16)),

        // Custom: switches from enthusiast builds.
        // Black is a heavy linear: one firm, bright bottom-out.
        Sound(id: "custom.black", name: "Black", family: .custom, press: SoundRecipe(
            layers: [
                .noise(gain: 3.5, decay: 0.003, filter: .bandpass(2600, q: 1.5)),
                .sine(1900, gain: 0.5, decay: 0.003),
                .sine(240, gain: 0.03, decay: 0.008, pitchEnd: 0.8),
            ],
            duration: 0.07, gain: 0.75, seed: 17)),
        // Jade has a click bar: a thicker, louder click than Blue.
        Sound(id: "custom.jade", name: "Jade", family: .custom, press: SoundRecipe(
            layers: [
                .noise(gain: 2.0, decay: 0.001, filter: .highpass(5000)),
                .sine(4200, gain: 0.9, decay: 0.0018),
                .sine(2700, gain: 0.5, decay: 0.0025),
                .noise(gain: 2.5, decay: 0.0025, filter: .bandpass(2400, q: 1.5), delay: 0.008),
                .sine(320, gain: 0.06, decay: 0.008, delay: 0.008),
            ],
            duration: 0.07, gain: 0.75, seed: 18)),
        // Panda is a strong tactile: a bump and a bottom-out close together.
        Sound(id: "custom.panda", name: "Panda", family: .custom, press: SoundRecipe(
            layers: [
                .noise(gain: 3.0, decay: 0.0025, filter: .bandpass(2500, q: 2)),
                .sine(2300, gain: 0.7, decay: 0.003),
                .noise(gain: 1.2, decay: 0.002, filter: .bandpass(1700, q: 1.5), delay: 0.004),
                .sine(220, gain: 0.04, decay: 0.008),
            ],
            duration: 0.07, gain: 0.75, seed: 19)),
        // Cream is an unlubed linear: a faint scratch on the way down, then a deep clack.
        Sound(id: "custom.cream", name: "Cream", family: .custom, press: SoundRecipe(
            layers: [
                .noise(gain: 0.4, attack: 0.006, decay: 0.001, filter: .bandpass(3500, q: 1)),
                .noise(gain: 3.5, decay: 0.003, filter: .bandpass(1300, q: 2.5), delay: 0.008),
                .noise(gain: 1.8, decay: 0.002, filter: .bandpass(2700, q: 1.5), delay: 0.008),
                .sine(1270, gain: 0.4, decay: 0.003, delay: 0.008),
                .sine(200, gain: 0.06, decay: 0.008, delay: 0.008),
            ],
            duration: 0.08, gain: 0.75, seed: 20)),

        // Vintage: old keyboards and the machines before them.
        // Spring is a buckling spring: a hard click with the spring ringing after it.
        Sound(id: "vintage.spring", name: "Spring", family: .vintage, press: SoundRecipe(
            layers: [
                .noise(gain: 3.0, decay: 0.004, filter: .bandpass(2500, q: 1)),
                .sine(2950, gain: 0.12, decay: 0.018),
                .sine(4400, gain: 0.08, decay: 0.012),
                .noise(gain: 3.5, decay: 0.006, filter: .bandpass(900, q: 1.5)),
                .sine(450, gain: 0.1, decay: 0.012),
                .sine(170, gain: 0.08, decay: 0.012),
            ],
            duration: 0.12, gain: 0.75, seed: 21)),
        // Alps is a sharp clack with a hollow ring under it.
        Sound(id: "vintage.alps", name: "Alps", family: .vintage, press: SoundRecipe(
            layers: [
                .noise(gain: 4.0, decay: 0.002, filter: .bandpass(3200, q: 2)),
                .sine(3100, gain: 0.4, decay: 0.0025),
                .triangle(1100, gain: 0.1, decay: 0.006),
                .noise(gain: 1.0, decay: 0.003, filter: .bandpass(1100, q: 3)),
            ],
            duration: 0.07, gain: 0.7, seed: 22)),
        // Typewriter is a typebar hitting the platen: a low thunk with a snap on top.
        Sound(id: "vintage.typewriter", name: "Typewriter", family: .vintage, press: SoundRecipe(
            layers: [
                .sine(105, gain: 0.2, decay: 0.012, pitchEnd: 0.8),
                .noise(gain: 5.0, decay: 0.008, filter: .bandpass(300, q: 2.5)),
                .noise(gain: 4.0, decay: 0.002, filter: .highpass(6000)),
                .sine(2200, gain: 0.2, decay: 0.004),
            ],
            duration: 0.1, gain: 0.85, seed: 23)),
        // Teletype is a solenoid clunk, then the mechanism rattling.
        Sound(id: "vintage.teletype", name: "Teletype", family: .vintage, press: SoundRecipe(
            layers: [
                .noise(gain: 4.5, decay: 0.012, filter: .bandpass(660, q: 1.5)),
                .noise(gain: 0.8, decay: 0.015, filter: .highpass(5000)),
                .sine(120, gain: 0.2, decay: 0.02),
                .noise(gain: 1.5, decay: 0.006, filter: .bandpass(2800, q: 1), delay: 0.02),
            ],
            duration: 0.15, gain: 0.8, seed: 24)),

        // Quiet: keyboards that keep it down.
        // Topre is a rubber dome over a spring: a soft, round "thup".
        Sound(id: "quiet.topre", name: "Topre", family: .quiet, press: SoundRecipe(
            layers: [
                .noise(gain: 4.0, decay: 0.006, filter: .bandpass(600, q: 1.5)),
                .sine(590, gain: 0.25, decay: 0.008, pitchEnd: 0.9),
                .noise(gain: 3.0, decay: 0.004, filter: .bandpass(1400, q: 1.5)),
                .sine(150, gain: 0.05, decay: 0.01),
            ],
            duration: 0.09, gain: 0.7, seed: 25)),
        // Silent is a dampened linear: a short, dull thud.
        Sound(id: "quiet.silent", name: "Silent", family: .quiet, press: SoundRecipe(
            layers: [
                .noise(gain: 4.0, decay: 0.003, filter: .lowpass(700)),
                .sine(180, gain: 0.1, decay: 0.006, pitchEnd: 0.8),
                .noise(gain: 2.0, decay: 0.002, filter: .bandpass(900, q: 1)),
            ],
            duration: 0.06, gain: 0.55, seed: 26)),
        // Laptop is a scissor switch: a small, flat tick.
        Sound(id: "quiet.laptop", name: "Laptop", family: .quiet, press: SoundRecipe(
            layers: [
                .noise(gain: 2.5, decay: 0.0015, filter: .bandpass(2600, q: 1.2)),
                .noise(gain: 2.0, decay: 0.003, filter: .bandpass(900, q: 1.5)),
                .sine(200, gain: 0.03, decay: 0.005),
            ],
            duration: 0.05, gain: 0.5, seed: 27)),
        // Membrane is an office rubber dome: the dome folds, then a mushy landing.
        Sound(id: "quiet.membrane", name: "Membrane", family: .quiet, press: SoundRecipe(
            layers: [
                .noise(gain: 4.0, decay: 0.006, filter: .bandpass(340, q: 2)),
                .noise(gain: 4.0, decay: 0.005, filter: .bandpass(700, q: 2.5), delay: 0.006),
                .sine(140, gain: 0.15, decay: 0.012),
            ],
            duration: 0.09, gain: 0.65, seed: 28)),
    ]
}
