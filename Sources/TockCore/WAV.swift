import Foundation

public enum WAV {
    /// Encodes mono samples as a 16-bit PCM WAV file.
    public static func data(samples: [Float], sampleRate: Int) -> Data {
        var data = Data()
        func append<T: FixedWidthInteger>(_ value: T) {
            withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) }
        }
        let byteCount = UInt32(samples.count * 2)

        data.append(contentsOf: Array("RIFF".utf8))
        append(36 + byteCount)
        data.append(contentsOf: Array("WAVE".utf8))
        data.append(contentsOf: Array("fmt ".utf8))
        append(UInt32(16))              // format chunk size
        append(UInt16(1))               // PCM
        append(UInt16(1))               // mono
        append(UInt32(sampleRate))
        append(UInt32(sampleRate * 2))  // bytes per second
        append(UInt16(2))               // bytes per frame
        append(UInt16(16))              // bits per sample
        data.append(contentsOf: Array("data".utf8))
        append(byteCount)

        for sample in samples {
            let clamped = sample.isFinite ? min(max(sample, -1), 1) : 0
            append(Int16((clamped * 32767).rounded()))
        }
        return data
    }
}
