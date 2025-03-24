import Foundation

/// Общий маркерный алиас для любого JSON объекта, полученного с использованием ``JSONSerialization``,
/// либо чеерз построение compatible словаря / массива
/// - Note: Из-за особенностей системы типов Swift, архитектурно было решено НЕ делать отдельный протокол,
/// ограничившись маркерным алиасом
public typealias JSON = Sendable

extension JSONSerialization {
    /// Получение `Data` из `JSON` объекта.
    ///
    /// - Parameters:
    ///  - object: Объект источник данных для генерации `Data`
    ///  - options: Дополнительные опции для сериализации
    /// - Important: `object` должен быть валидным для сериализации
    public static func jsonData(
        with object: JSON,
        options: JSONSerialization.WritingOptions = []
    ) throws -> Data {
        guard isValidJSONObject(object) else {
            throw EncodingError.invalidValue(
                object,
                EncodingError.Context(
                    codingPath: [],
                    debugDescription: "Invalid JSON object"
                )
            )
        }

        return try data(
            withJSONObject: object,
            options: options
        )
    }

    /// Получение `JSON` объекта в виде строки.
    ///
    /// - Parameters:
    ///  - object: Объект источник данных для генерации `JSON`
    ///  - options: Дополнительные опции для сериализации
    @inlinable
    public static func jsonString(
        with object: JSON,
        options: JSONSerialization.WritingOptions = []
    ) throws -> String {
        let data = try jsonData(with: object, options: options)
        return String(decoding: data, as: UTF8.self)
    }

    /// Получить JSON объект, выбранного типа из сырых данных
    /// - Parameters:
    ///  - data: Данные для десериализации
    ///  - options: Дополнительные опции для десериализации
    public static func jsonObject<T: JSON>(
        _: T.Type,
        with data: Data,
        options: JSONSerialization.ReadingOptions = []
    ) throws -> T {
        let object = try JSONSerialization.jsonObject(
            with: data,
            options: options.union(.fragmentsAllowed)
        )

        guard let value = object as? T else {
            throw DecodingError.typeMismatch(
                T.self,
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Incompatible json type "
                        + String(describing: type(of: object))
                        + " when expected "
                        + String(describing: T.self)
                )
            )
        }

        return value
    }

    /// Получить JSON объект, выбранного типа из сырой JSON строки
    /// - Parameters:
    ///  - data: Данные для десериализации
    ///  - options: Дополнительные опции для десериализации
    @inlinable
    public static func jsonObject<T: JSON>(
        _: T.Type,
        with string: String,
        options: JSONSerialization.ReadingOptions = []
    ) throws -> T {
        try jsonObject(T.self, with: string.utf8Data(), options: options)
    }
}

extension JSONSerialization.WritingOptions {
    /// Ключи - отсортированы, вывод - отформатирован
    public static var prettyAndStable: Self {
        [.sortedKeys, .prettyPrinted]
    }

    /// Ключи - отсортированы, вывод - отформатирован
    @available(*, deprecated, message: "Используйте опции напрямую")
    public static func sortedKeys(_ isSortedKeys: Bool) -> Self {
        isSortedKeys ? .sortedKeys : []
    }

    /// Ключи - отсортированы, вывод - отформатирован
    @available(*, deprecated, message: "Используйте опции напрямую")
    public static func prettyAndStable(_ isPrettyAndStable: Bool) -> Self {
        isPrettyAndStable ? .prettyAndStable : []
    }
}

extension Decodable {
    @inlinable
    public init(jsonObject: JSON, decoder: JSONDecoder = JSONDecoder()) throws {
        let data = try JSONSerialization.jsonData(with: jsonObject)
        self = try decoder.decode(Self.self, from: data)
    }
}
