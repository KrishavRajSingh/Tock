import Foundation
import TockCore

// Usage: tock-render [output-directory]
// Writes <sound-id>-press.wav, -release.wav, -scroll.wav and -key.wav for every sound.

let directory = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "renders")
let sampleRate = 48_000

do {
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    for sound in SoundLibrary.sounds {
        for (suffix, recipe) in [("press", sound.press), ("release", sound.release), ("scroll", sound.scroll), ("key", sound.key)] {
            let samples = Synth.render(recipe, sampleRate: Double(sampleRate))
            let file = directory.appendingPathComponent("\(sound.id)-\(suffix).wav")
            try WAV.data(samples: samples, sampleRate: sampleRate).write(to: file)
        }
    }
    print("Wrote \(SoundLibrary.sounds.count * 4) files to \(directory.path)")
} catch {
    FileHandle.standardError.write(Data("tock-render: \(error.localizedDescription)\n".utf8))
    exit(1)
}
