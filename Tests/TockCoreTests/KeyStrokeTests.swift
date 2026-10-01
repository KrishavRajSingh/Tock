import Testing
@testable import TockCore

@Suite struct KeyStrokeTests {
    @Test func keyDownIsAPress() {
        #expect(KeyStroke.phase(keyDown: true, autorepeat: false) == .press)
    }

    @Test func keyUpIsARelease() {
        #expect(KeyStroke.phase(keyDown: false, autorepeat: false) == .release)
    }

    @Test func heldKeyRepeatsMakeNoSound() {
        #expect(KeyStroke.phase(keyDown: true, autorepeat: true) == nil)
    }
}
