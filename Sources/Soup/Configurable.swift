public protocol Configurable {}

extension Configurable {
    /// Вернуть объект с применением изменений в closure
    ///
    /// - Important: Для Value type создает, изменяет и возвращает __копию__ .
    /// Для reference type – исходный инстанс
    @discardableResult
    public func configure(
        _ block: (inout Self) throws -> Void
    ) rethrows -> Self {
        var obj = self
        try block(&obj)
        return obj
    }
}

extension Array: Configurable {}
