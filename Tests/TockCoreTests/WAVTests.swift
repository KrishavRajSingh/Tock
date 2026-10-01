import Foundation
import Testing
@testable import TockCore

@Suite struct WAVTests {
    func uint32(_ data: Data, at offset: Int) -> UInt32 {
        data.subdata(in: offset..<offset + 4).withUnsafeBytes { $0.loadUnaligned(as: UInt32.self) }
    }

    func int16(_ data: Data, at offset: Int) -> Int16 {
        data.subdata(in: offset..<offset + 2).withUnsafeBytes { $0.loadUnaligned(as: Int16.self) }
    }

    @Test func headerDescribesMono16BitPCM() {
        let data = WAV.data(samples: [0, 0.5, -0.5], sampleRate: 48_000)
        #expect(data.count == 44 + 6)
        #expect(String(decoding: data[0..<4], as: UTF8.self) == "RIFF")
        #expect(uint32(data, at: 4) == 36 + 6)
        #expect(String(decoding: data[8..<12], as: UTF8.self) == "WAVE")
        #expect(uint32(data, at: 24) == 48_000)
        #expect(uint32(data, at: 28) == 96_000)
        #expect(String(decoding: data[36..<40], as: UTF8.self) == "data")
        #expect(uint32(data, at: 40) == 6)
    }

    @Test func samplesAreScaledAndClamped() {
        let data = WAV.data(samples: [1, -1, 3, -3, .nan, 0], sampleRate: 48_000)
        let values = (0..<6).map { int16(data, at: 44 + $0 * 2) }
        #expect(values == [32767, -32767, 32767, -32767, 0, 0])
    }

    @Test func emptyInputGivesHeaderOnly() {
        #expect(WAV.data(samples: [], sampleRate: 48_000).count == 44)
    }
}
