import Testing
@testable import TockCore

@Suite struct SplitMix64Tests {
    @Test func sameSeedGivesSameSequence() {
        var a = SplitMix64(seed: 42)
        var b = SplitMix64(seed: 42)
        for _ in 0..<100 { #expect(a.next() == b.next()) }
    }

    @Test func differentSeedsGiveDifferentSequences() {
        var a = SplitMix64(seed: 1)
        var b = SplitMix64(seed: 2)
        #expect(a.next() != b.next())
    }

    @Test func unitValuesStayInRangeAndVary() {
        var rng = SplitMix64(seed: 7)
        let values = (0..<10_000).map { _ in rng.nextUnit() }
        #expect(values.allSatisfy { $0 >= -1 && $0 < 1 })
        #expect(values.contains { $0 > 0.5 })
        #expect(values.contains { $0 < -0.5 })
    }
}
