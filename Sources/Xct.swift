import XCTest

/// Namespace под все тестовые ассерты SberDevices.
/// Расширяет и заменяет некоторые методы из XCT.
/// Подразумевается повсеместное использование Xtc место системных XCTAssert....
public enum Xct {
    /// Остановить тест с ошибкой
    public static func fail(
        _ message: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTFail(message, file: file, line: line)
    }

    /// Остановить тест, оставив комментарий с пояснением
    /// Не считается провалом теста (если ассерты до не успели упасть, кейс будет зеленым)
    ///
    /// Нужно для временного отключения проблемного теста,
    /// подразумевает TODO коммент и скорое исправление
    public static func skip(
        _ message: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        throw XCTSkip(message, file: file, line: line)
    }

    /// Задает название выпоняемым действиям в тесте и отчете об их выполнении
    @MainActor
    public static func step(
        _ name: String,
        _ step: () throws -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTContext.runActivity(named: name) { _ in
            do {
                try step()
            } catch {
                XCTFail(
                    "Выполнение шага завершилось с ошибкой: \(error.localizedDescription)",
                    file: file,
                    line: line
                )
            }
        }
    }

    /// Хелпер для тестов, который декодирует и сравнивает ожидаемую и полученную ошибки
    public static func assertThrowsError<T, E: Error & Equatable>(
        _ expression: () throws -> T, // must NOT be @autoclosure, see: CODESTYLE_GUIDE.md
        _ expectedError: E,
        _ message: String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertThrowsError(
            try expression(),
            message,
            file: file,
            line: line
        ) { error in
            guard let catchedError = error as? E else {
                XCTFail(
                    """
                    Error type mismatch, \
                    expected:  \(type(of: expectedError)), \(expectedError.localizedErrorDescription), \
                    catched: \(type(of: error)), \(error.localizedErrorDescription)
                    """,
                    file: file,
                    line: line
                )
                return
            }
            Xct.assertEqual(catchedError, expectedError, file: file, line: line)
        }
    }

    /// Хелпер для тестов, который декодирует и сравнивает ожидаемую и полученную ошибки
    public static func assertThrowsError<T, E: Error & Equatable>(
        _ expression: () async throws -> T, // must NOT be @autoclosure, see: CODESTYLE_GUIDE.md
        _ expectedError: E,
        _: String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            _ = try await expression()

            XCTFail(
                "No error was thrown, expected: \(expectedError.localizedErrorDescription)",
                file: file,
                line: line
            )
        } catch let error as E {
            Xct.assertEqual(error, expectedError, file: file, line: line)
        } catch {
            XCTFail(
                """
                Error type mismatch, \
                expected:  \(type(of: expectedError)), \(expectedError.localizedErrorDescription), \
                catched: \(type(of: error)), \(error.localizedErrorDescription)
                """,
                file: file,
                line: line
            )
        }
    }

    public static func assertNoThrow<T>(
        _ expression: () async throws -> T, // must NOT be @autoclosure, see: CODESTYLE_GUIDE.md
        message: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            _ = try await expression()
        } catch {
            let message = (message ?? "Assertion failed") +
            ", error: \(error.localizedErrorDescription)"
            XCTFail(
                message,
                file: file,
                line: line
            )
        }
    }

    /// Хелпер для тестов, который проверяет выбрасывает ли выражение ошибку
    /// - Attention:
    /// Следует __всегда__ использовать в тестах для отлова `Swift.Error`
    /// вместо `XCTAssertNoThrow()`, срабатывающего только на `NSException`
    public static func assertNoThrow<T>(
        _ expression: () throws -> T, // must NOT be @autoclosure, see: CODESTYLE_GUIDE.md
        message: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        do {
            _ = try expression()
        } catch {
            let message = (message ?? "Assertion failed") +
            ", error: \(error.localizedErrorDescription)"
            XCTFail(
                message,
                file: file,
                line: line
            )
        }
    }

    public static func assertFailure<Success, Failure, E: Error & Equatable>(
        _ result: Result<Success, Failure>?,
        _ expectedError: E,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        Xct.assertThrowsError(
            { try result?.get() },
            expectedError,
            "Tested result isn't .failure, it's: \(result)",
            file: file,
            line: line
        )
    }

    public static func assertFailure<Success, Failure: Equatable>(
        _ result: Result<Success, Failure>?,
        _ expectedError: Failure,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        switch result {
        case .success:
            XCTFail(
                "Assertion failed, result is: \(result)",
                file: file,
                line: line
            )
        case let .failure(error):
            Xct.assertEqual(error, expectedError, file: file, line: line)
        case .none:
            XCTFail("Assertion failed, result is .none", file: file, line: line)
        }
    }

    /// Хелпер для тестов который ожидает наличие и равенство от `expression` `true`
    public static func assertTrue(
        _ expression: @autoclosure () throws -> Bool?,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        do {
            guard let value = try expression() else {
                return XCTFail(
                    "Expected to get wrapped value",
                    file: file,
                    line: line
                )
            }
            XCTAssertTrue(value, message(), file: file, line: line)
        } catch {
            return XCTFail(
                "Unexpected error received \(error.localizedErrorDescription)",
                file: file,
                line: line
            )
        }
    }

    public static func assertFalse(
        _ expression: @autoclosure () throws -> Bool?,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        do {
            guard let value = try expression() else {
                return XCTFail(
                    "Expected to get wrapped value",
                    file: file,
                    line: line
                )
            }
            XCTAssertFalse(value, message(), file: file, line: line)
        } catch {
            return XCTFail(
                "Unexpected error received \(error.localizedErrorDescription)",
                file: file,
                line: line
            )
        }
    }

    /// Объединение ассерта на единственность элемента в коллекции с его возвратом.
    /// Если элементов > 1, вернёт `nil`.
    @discardableResult
    public static func assertSingle<T: Collection>(
        _ collection: T,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> T.Element? {
        guard !collection.isEmpty else {
            XCTFail("\(collection) is empty", file: file, line: line)
            return nil
        }
        guard collection.count == 1 else {
            XCTFail("\(collection) contains more than one element.", file: file, line: line)
            return nil
        }
        return collection.first
    }

    /// Проверка опционала на равенство к nil
    @inlinable
    public static func assertNil<T>(
        _ value: T?,
        _ message: String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertNil(
            value,
            "\(String(describing: value)) is not nil. \(message)",
            file: file,
            line: line
        )
    }

    /// Проверка опционала на отличие от nil
    @inlinable
    public static func assertNotNil<T>(
        _ value: T?,
        _ message: String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertNotNil(
            value,
            "\(String(describing: value)) is nil. \(message)",
            file: file,
            line: line
        )
    }

    /// Проверка wrapped опционала на равенство к nil
    @inlinable
    public static func assertWrappedNil<T>(
        _ value: T?,
        _: String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let value else {
            XCTFail("\(String(describing: value)) is not wrapped", file: file, line: line)
            return
        }

        assertTrue((value as AnyObject) is NSNull)
    }

    /// Проверка wrapped опционала на отличие от nil
    @inlinable
    public static func assertWrappedNotNil<T>(
        _ value: T?,
        _: String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let value else {
            XCTFail("\(String(describing: value)) is not wrapped", file: file, line: line)
            return
        }

        assertFalse((value as AnyObject) is NSNull)
    }

    /// Проверка коллекции на полное отсутствие элементов
    public static func assertEmpty<T: Collection>(
        _ collection: T,
        _ message: String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            collection.isEmpty,
            "\(collection) is not empty. \(message)",
            file: file,
            line: line
        )
    }

    /// Проверка коллекции на наличие хотя бы 1 элемента
    public static func assertNonEmpty<T: Collection>(
        _ collection: T,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertFalse(
            collection.isEmpty,
            "\(collection) is empty",
            file: file,
            line: line
        )
    }

    public static func assertSuccess<Success: Equatable, Failure>(
        _ result: Result<Success, Failure>?,
        _ expectedSuccess: Success,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        switch result {
        case let .success(success):
            Xct.assertEqual(success, expectedSuccess, file: file, line: line)
        case .failure:
            XCTFail(
                "Assertion failed, result is: \(result)",
                file: file,
                line: line
            )
        case .none:
            XCTFail("Assertion failed, result is .none", file: file, line: line)
        }
    }

    public static func assertSuccess<Failure>(
        _ result: Result<Void, Failure>?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        switch result {
        case .success:
            XCTAssert(true)
        case .failure:
            XCTFail(
                "Assertion failed, result is: \(result)",
                file: file,
                line: line
            )
        case .none:
            XCTFail("Assertion failed, result is .none", file: file, line: line)
        }
    }

    public static func assertEqualAsync<T: Equatable>(
        _ received: @autoclosure () async throws -> T,
        _ expected: @autoclosure () async throws -> T,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            let expected = try await expected()
            let received = try await received()

            Xct.assertEqual(received, expected, message(), file: file, line: line)
        } catch {
            XCTFail("Caught error in assertEqual: \(error)", file: file, line: line)
        }
    }

    public static func assertEqual<T: Equatable>(
        _ received: @autoclosure () throws -> T,
        _ expected: @autoclosure () throws -> T,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        do {
            let expected = try expected()
            let received = try received()

            XCTAssertEqual(received, expected, message(), file: file, line: line)
        } catch {
            XCTFail("Caught error in assertEqual: \(error)", file: file, line: line)
        }
    }

    public static func assertNotEqual<T: Equatable>(
        _ received: @autoclosure () throws -> T,
        _ expected: @autoclosure () throws -> T,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        do {
            let expected = try expected()
            let received = try received()
            XCTAssertFalse(
                expected == received,
                "Assertion failed. Elements equal. "
                    + message(),
                file: file,
                line: line
            )
        } catch {
            XCTFail("Caught error in assertNotEqual: \(error)", file: file, line: line)
        }
    }

    public static func assertEqual<F: FloatingPoint>(
        _ lhs: F?,
        _ rhs: F,
        accuracy: F,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let lhs else {
            XCTFail("Assertion failed. Left value is nil", file: file, line: line)
            return
        }

        XCTAssertEqual(lhs, rhs, accuracy: accuracy, file: file, line: line)
    }

    public static func assertEqual<Element>(
        _ lhs: [Element],
        _ rhs: [Element],
        isElementsEqual: (Element, Element) -> Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard lhs.count == rhs.count else {
            XCTFail("Assertion failed. Different elements count: \(lhs.count) vs \(rhs.count)", file: file, line: line)
            return
        }

        for index in 0 ..< lhs.count where !isElementsEqual(lhs[index], rhs[index]) {
            XCTFail("Assertion failed. Elements not equal: \(lhs[index]) vs \(rhs[index])", file: file, line: line)
        }
    }

    public static func assertEqualReferences(
        _ lhs: AnyObject?,
        _ rhs: AnyObject?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        if lhs !== rhs {
            XCTFail(
                "Assertion failed, references are different",
                file: file,
                line: line
            )
        }
    }

    public static func assertContains<T: OptionSet>(
        _ optionSet: T,
        value: T.Element,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            optionSet.contains(value),
            "Options set(\(optionSet)) doesn't contain value (\(value)",
            file: file,
            line: line
        )
    }

    public static func assertContains<T: Sequence>(
        _ sequence: T,
        value: T.Element,
        file: StaticString = #filePath,
        line: UInt = #line
    ) where T.Element: Equatable {
        XCTAssertTrue(
            sequence.contains(value),
            "Sequence (\(sequence)) doesn't contain value (\(value)",
            file: file,
            line: line
        )
    }

    public static func assertNotContain<T: OptionSet>(
        _ optionSet: T,
        value: T.Element,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertFalse(
            optionSet.contains(value),
            "Options set(\(optionSet)) contains value (\(value)",
            file: file,
            line: line
        )
    }

    public static func unwrap<T>(
        _ value: T?,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> T {
        try XCTUnwrap(
            value,
            message(),
            file: file,
            line: line
        )
    }
}
