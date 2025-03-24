import CoreGraphics
import Foundation

extension String {
    /// Проверяет потенциальный `scheme` компонент `URL` на правильность формата
    public var isValidURLScheme: Bool {
        var validSymbols = Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
        guard
            let firstChar = self.first,
            validSymbols.contains(firstChar)
        else { return false }

        validSymbols.formUnion("0123456789-.+")
        for char in self {
            guard validSymbols.contains(char) else { return false }
        }
        return true
    }

    public func makeAttributed(
        with attributes: [NSAttributedString.Key: Any]?
    ) -> NSAttributedString {
        NSAttributedString(string: self, attributes: attributes)
    }

    public func makeMutableAttributed(
        with attributes: [NSAttributedString.Key: Any]?
    ) -> NSMutableAttributedString {
        NSMutableAttributedString(string: self, attributes: attributes)
    }

    public func toBase64() -> String {
        Data(self.utf8).base64EncodedString()
    }

    public func toNSString() -> NSString {
        NSString(string: self)
    }

    /// Возвращает `UTF8` data с этой строки
    /// - Note: Внутренние  конвертации из массива `Character` в `UTF8` всегда валидны, поэтому
    /// `nil` никогда не вернется https://stackoverflow.com/a/46152738
    public func utf8Data() -> Data {
        guard let data = data(using: .utf8) else {
            fatalError("Unexpected null for UTF8 data conversion")
        }
        return data
    }

    public func removing(prefixes: [String]) -> String {
        prefixes.reduce(self) { $0.removing(prefix: $1) }
    }

    public func removing(prefix: String) -> String {
        if !hasPrefix(prefix) { return self }
        return String(dropFirst(prefix.count))
    }

    public func removing(suffix: String) -> String {
        if !hasSuffix(suffix) { return self }
        return String(dropLast(suffix.count))
    }

    /// Генерирует строку заданной длины из переданного можества символов
    /// и конвертирует в формат `Base64URL`
    ///
    /// - Parameters:
    ///   - characters: Множоство символов для формирования строки
    ///   - count: Длина выходной строки
    /// - Returns: Строка случайных символов или пустая, в случае отсутствия ``characters``
    public static func random(
        from characters: Set<Character>,
        count: Int
    ) -> String {
        String((0 ..< count).compactMap { _ in characters.randomElement() })
    }
}

extension String? {
    public static func + (lhs: String?, rhs: String?) -> String? {
        if let lhs {
            if let rhs {
                lhs + rhs
            } else {
                lhs
            }
        } else {
            if let rhs {
                rhs
            } else {
                nil
            }
        }
    }
}

extension String {
    public static func makeUnique() -> String {
        UUID().uuidString
    }
}
