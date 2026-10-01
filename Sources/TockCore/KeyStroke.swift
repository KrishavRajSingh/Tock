public enum KeyStroke {
    /// The sound phase for a keyboard event, or nil for none. Repeats from a
    /// held key make no sound. Which key it was is never looked at.
    public static func phase(keyDown: Bool, autorepeat: Bool) -> ClickPhase? {
        if autorepeat { return nil }
        return keyDown ? .press : .release
    }
}
