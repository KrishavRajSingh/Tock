import Testing
@testable import TockCore

@Suite struct MouseButtonTests {
    @Test func mapsTheThreeMainButtons() {
        #expect(MouseButton(buttonNumber: 0) == .left)
        #expect(MouseButton(buttonNumber: 1) == .right)
        #expect(MouseButton(buttonNumber: 2) == .middle)
    }

    @Test func ignoresExtraButtons() {
        for number in [3, 4, 5, 31, -1] {
            #expect(MouseButton(buttonNumber: number) == nil)
        }
    }
}
