import AVFoundation
import TockCore

/// Plays pre-rendered click sounds. Buffers are rendered when a sound is
/// loaded; playing only schedules a ready buffer on the next voice.
final class AudioPlayer {
    static let voiceCount = 8

    var onRunningChange: ((Bool) -> Void)?

    var volume: Float = Float(TockSettings.defaultVolume) {
        didSet { voices.forEach { $0.volume = volume } }
    }

    var isRunning: Bool { engine.isRunning }

    private let engine = AVAudioEngine()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 1)!
    private let voices = (0..<AudioPlayer.voiceCount).map { _ in AVAudioPlayerNode() }
    private let renderQueue = DispatchQueue(label: "tock.render", qos: .userInitiated)
    private var connected = false
    private var nextVoice = 0
    private var loadGenerations: [SoundTarget: Int] = [:]
    private var buffers: [SoundTarget: BufferSet] = [:]

    /// The ready-to-play buffers of one sound, one per pitch variant.
    private struct BufferSet {
        var press: [AVAudioPCMBuffer] = []
        var release: [AVAudioPCMBuffer] = []
        var scroll: [AVAudioPCMBuffer] = []
    }
    private var observer: NSObjectProtocol?

    init() {
        voices.forEach { engine.attach($0) }
        // Fires when the output device changes; the engine has stopped itself.
        observer = NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main
        ) { [weak self] _ in
            self?.start()
        }
    }

    deinit {
        if let observer { NotificationCenter.default.removeObserver(observer) }
    }

    /// Starts the engine if it is not running. Safe to call repeatedly.
    @discardableResult
    func start() -> Bool {
        if !engine.isRunning {
            // With no output device the output format has no channels, and
            // connecting or starting would raise an Objective-C exception.
            let output = engine.outputNode.outputFormat(forBus: 0)
            if output.channelCount > 0, output.sampleRate > 0 {
                if !connected {
                    voices.forEach { engine.connect($0, to: engine.mainMixerNode, format: format) }
                    connected = true
                }
                do {
                    try engine.start()
                } catch {
                    NSLog("Tock: audio engine failed to start: \(error.localizedDescription)")
                }
            }
        }
        onRunningChange?(engine.isRunning)
        return engine.isRunning
    }

    /// Renders `sound` for `target` off the main thread, then swaps the
    /// buffers in on the main thread. If another load for the same target
    /// starts meanwhile, this one is dropped.
    func load(_ sound: Sound, for target: SoundTarget, completion: (() -> Void)? = nil) {
        let generation = (loadGenerations[target] ?? 0) + 1
        loadGenerations[target] = generation
        let format = format
        renderQueue.async {
            // The keyboard uses the sound's lighter key variant and never scrolls.
            let press = target == .mouse ? sound.press : sound.key
            let set = BufferSet(
                press: Self.buffers(for: press, format: format),
                release: Self.buffers(for: sound.release, format: format),
                scroll: target == .mouse ? Self.buffers(for: sound.scroll, format: format) : [])
            DispatchQueue.main.async { [weak self] in
                guard let self, generation == self.loadGenerations[target] else { return }
                self.buffers[target] = set
                completion?()
            }
        }
    }

    func play(_ phase: ClickPhase, for target: SoundTarget) {
        guard let set = buffers[target] else { return }
        play(oneOf: phase == .press ? set.press : set.release)
    }

    func playScrollTick() {
        play(oneOf: buffers[.mouse]?.scroll ?? [])
    }

    private func play(oneOf buffers: [AVAudioPCMBuffer]) {
        guard engine.isRunning, let buffer = buffers.randomElement() else { return }
        let voice = voices[nextVoice]
        nextVoice = (nextVoice + 1) % voices.count
        voice.scheduleBuffer(buffer, at: nil, options: .interrupts)
        if !voice.isPlaying { voice.play() }
    }

    private static func buffers(for recipe: SoundRecipe, format: AVAudioFormat) -> [AVAudioPCMBuffer] {
        SoundLibrary.pitchVariants.compactMap { shift in
            let samples = Synth.render(recipe, sampleRate: format.sampleRate, pitchShift: shift)
            let count = AVAudioFrameCount(samples.count)
            guard count > 0,
                let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: count),
                let channel = buffer.floatChannelData?[0]
            else { return nil }
            samples.withUnsafeBufferPointer { channel.update(from: $0.baseAddress!, count: samples.count) }
            buffer.frameLength = count
            return buffer
        }
    }
}
