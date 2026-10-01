import Testing
@testable import TockCore

@Suite struct ScrollTickerTests {
    /// Feeds events (delta, precise, time) to a fresh ticker and returns
    /// which of them ticked.
    func ticks(_ events: [(Double, Bool, Double)]) -> [Bool] {
        var ticker = ScrollTicker()
        return events.map { ticker.shouldTick(delta: $0.0, precise: $0.1, time: $0.2) }
    }

    @Test func eachWheelNotchTicks() {
        #expect(ticks([(1, false, 0), (-1, false, 0.1)]) == [true, true])
    }

    @Test func zeroDeltaNeverTicks() {
        #expect(ticks([(0, false, 0), (0, true, 0.1)]) == [false, false])
    }

    @Test func trackpadTicksOncePerFortyPoints() {
        let events: [(Double, Bool, Double)] = [(10, true, 0), (-10, true, 0.01), (10, true, 0.02), (10, true, 0.03)]
        #expect(ticks(events) == [false, false, false, true])
    }

    @Test func leftoverDistanceCarriesToNextTick() {
        #expect(ticks([(50, true, 0), (30, true, 0.1)]) == [true, true])
    }

    @Test func ticksAreRateLimited() {
        #expect(ticks([(1, false, 0), (1, false, 0.01), (1, false, 0.05)]) == [true, false, true])
    }

    @Test func hugeFlingGivesOneTickAndNoBacklog() {
        // 500 leaves 20 over; 5 more is still short of 40.
        #expect(ticks([(500, true, 0), (5, true, 0.1)]) == [true, false])
    }

    @Test func pauseStartsANewGesture() {
        #expect(ticks([(30, true, 0), (30, true, 1)]) == [false, false])
    }

    @Test func nonFiniteInputIsIgnoredAndDoesNotStick() {
        let events: [(Double, Bool, Double)] = [
            (.nan, true, 0), (.infinity, true, 0.01), (40, true, .nan), (40, true, 0.02),
        ]
        #expect(ticks(events) == [false, false, false, true])
    }
}
