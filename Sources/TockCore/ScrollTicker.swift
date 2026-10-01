/// Decides when scrolling should make a sound. A mouse wheel ticks once per
/// notch; a trackpad ticks once per `pointsPerTick` of travel. Ticks are rate
/// limited so a fast scroll purrs instead of buzzing.
public struct ScrollTicker: Sendable {
    public static let pointsPerTick = 40.0
    /// Shortest time between two ticks, in seconds.
    public static let minInterval = 0.03
    /// A pause this long starts a new gesture and drops leftover travel.
    public static let gestureGap = 0.25

    private var travelled = 0.0
    private var lastEvent = -Double.infinity
    private var lastTick = -Double.infinity

    public init() {}

    /// `delta` is the scroll distance of one event (sign ignored); `precise`
    /// is true for trackpads, where it is in points; `time` is in seconds.
    public mutating func shouldTick(delta: Double, precise: Bool, time: Double) -> Bool {
        guard delta.isFinite, time.isFinite, delta != 0 else { return false }
        if time - lastEvent > Self.gestureGap { travelled = 0 }
        lastEvent = time

        if precise {
            travelled += abs(delta)
            guard travelled >= Self.pointsPerTick else { return false }
            travelled = travelled.truncatingRemainder(dividingBy: Self.pointsPerTick)
        }
        guard time - lastTick >= Self.minInterval else { return false }
        lastTick = time
        return true
    }
}
