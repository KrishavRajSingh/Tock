public enum MouseButton: Equatable, Sendable {
    case left, right, middle

    /// Maps a system button number. Buttons beyond the first three (back,
    /// forward and so on) are not handled.
    public init?(buttonNumber: Int) {
        switch buttonNumber {
        case 0: self = .left
        case 1: self = .right
        case 2: self = .middle
        default: return nil
        }
    }
}

public enum ClickPhase: Equatable, Sendable {
    case press, release
}
