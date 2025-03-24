extension Bool {
    /// Аналог `!`, полезен для длинных цепей вычисления флага
    @inlinable public var toggled: Bool { !self }
}

extension Bool {
    public var string: String {
        self ? "true" : "false"
    }
}
