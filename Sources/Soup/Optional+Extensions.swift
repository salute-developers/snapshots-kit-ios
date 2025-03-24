import Foundation

public enum OptionalError: LocalizedError, Equatable {
    case noValue(String)

    public var errorDescription: String? {
        switch self {
        case let .noValue(description):
            return "Got null value while unwrapping optional in " + description
        }
    }
}

extension Optional {
    /// Содержит ли опционал обёрнутое значение
    @inlinable public var isSome: Bool { self != nil }

    /// Равен ли опционал `nil`
    @inlinable public var isNone: Bool { self == nil }
}

extension Optional where Wrapped == Bool {
    /// Инвертированный `Bool?` из `wrappedValue` либо `nil`
    @inlinable
    public static prefix func ! (_ optional: Bool?) -> Bool? {
        optional?.toggled
    }
}

extension Optional where Wrapped: Collection {
    /// Проверяет этот опционал на наличие элементов. В случае
    /// отсутствие значения либо пустом массиве возвращает `False`.
    public var isNullOrEmpty: Bool {
        guard let wrapped = self else {
            return true
        }
        return wrapped.isEmpty
    }
}

extension Optional {
    @inlinable
    public func get(elseThrow error: @autoclosure () -> Error) throws -> Wrapped {
        guard let value = self else {
            throw error()
        }
        return value
    }

    @inlinable
    public func get(elseThrow key: @autoclosure () -> String) throws -> Wrapped {
        guard let value = self else {
            throw OptionalError.noValue(key())
        }
        return value
    }

    @inlinable
    public func asResult(throwing key: @autoclosure () -> String) -> Result<Wrapped, Error> {
        guard let value = self else {
            return .failure(OptionalError.noValue(key()))
        }
        return .success(value)
    }

    @inlinable
    public func get(file: String = #file, function: String = #function, line: Int = #line) throws -> Wrapped {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        return try get(elseThrow: OptionalError.noValue(fileName + ":" + String(describing: line) + ":" + function))
    }
}

extension Optional {
    /// Вызывает переданный клоужер с обернутым значением, если оно есть
    @inlinable
    public func ifSome(_ perform: (Wrapped) throws -> Void) rethrows {
        if let wrapped = self {
            try perform(wrapped)
        }
    }
}
