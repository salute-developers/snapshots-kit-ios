import SwiftUI
import UIKit
import XCTest

// MARK: - Xct

extension Xct {
    /// Ассерт на визуальное соответствие снимка (snapshot) тестируемого UIView (sut)
    /// ожидаемому изображению (reference)
    ///
    /// - Note: Универсальный метод. Позволяет сделать запись нового reference.
    /// Сценарий определяет `mode`
    public static func snapshotAsync(
        testName: String = #function,
        file: StaticString = #filePath,
        line: UInt = #line,
        matcher: SnapshotMatcherKind = .default,
        mode: SnapshotMode = .verify,
        deviceGroup: SnapshotDeviceGroup = .phone,
        includeAccessibility: Bool = false,
        prepareSut: @MainActor @escaping (SnapshotDevice) throws -> SnapshotSut
    ) async {
        var snapshotKinds: [SnapshotKind] = [.interface]
        if includeAccessibility {
            snapshotKinds.append(.accessibility)
        }
        var errors = await withTaskGroup(of: Error?.self, returning: [Error].self) { group in
            for screen in deviceGroup.devices {
                for snapshotKind in snapshotKinds {
                    group.addTask {
                        do {
                            let snapshot = try await Task { @MainActor in
                                try SnapshotCanvas(
                                    sut: prepareSut(screen),
                                    screen: screen,
                                    snapshotKind: snapshotKind
                                )
                                .capture()
                                .get(elseThrow: SnapshotError.failedToMakeSnapshot)
                            }.value
                            let files = try SnapshotFiles(
                                device: screen,
                                testName: testName,
                                suffix: snapshotKind.referenceFileSuffix,
                                testFile: file,
                                isComparisonFilesUseful: true
                            )
                            try matcher.run(
                                snapshot: snapshot,
                                files: files,
                                mode: mode,
                                screen: screen
                            )
                            return nil
                        } catch {
                            return error
                        }
                    }
                }
            }

            return await group.reduce(into: [Error]()) {
                if let error = $1 {
                    $0.append(error)
                }
            }
        }
        switch mode {
        case .verify:
            break
        case .record:
            errors.append(SnapshotError.recordModeEnabled)
        }
        for error in errors {
            XCTFail(error.localizedErrorDescription, file: file, line: line)
        }
    }

    /// Ассерт на получение ожидаемых ошибок
    /// при проверке на визуальное соответствие снимка (snapshot) тестируемого UIView (sut)
    /// ожидаемому изображению (reference)
    ///
    /// - Note: Универсальный метод. Позволяет сделать запись нового reference (в prepareReference).
    /// Сценарий определяет `mode`
    static func snapshotThrows(
        testName: String = #function,
        file: StaticString = #filePath,
        line: UInt = #line,
        matcher: SnapshotMatcherKind = .default,
        mode: SnapshotMode = .verify,
        deviceGroup: SnapshotDeviceGroup = .phone,
        expected: [SnapshotError.Kind?],
        prepareReference: @MainActor @escaping (SnapshotDevice) throws -> SnapshotSut,
        prepareSut: @MainActor @escaping (SnapshotDevice) throws -> SnapshotSut
    ) async {
        var errors = await withTaskGroup(of: (Int, Error?).self, returning: [Error?].self) { group in
            for index in deviceGroup.devices.indices {
                let screen = deviceGroup.devices[index]
                group.addTask {
                    do {
                        let snapshot = try await Task { @MainActor in
                            try SnapshotCanvas(
                                sut: mode.prepareSnapshotView(
                                    device: screen,
                                    prepareReference: prepareReference,
                                    prepareSut: prepareSut
                                ),
                                screen: screen
                            )
                            .capture()
                            .get(elseThrow: SnapshotError.failedToMakeSnapshot)
                        }.value
                        let files = try SnapshotFiles(
                            device: screen,
                            testName: testName,
                            suffix: "",
                            testFile: file,
                            isComparisonFilesUseful: false
                        )
                        try matcher.run(
                            snapshot: snapshot,
                            files: files,
                            mode: mode,
                            screen: screen
                        )
                        return (index, nil)
                    } catch {
                        return (index, error)
                    }
                }
            }

            var result: [Error?] = Array(repeating: nil, count: expected.count)
            while let next = await group.next() {
                result[next.0] = next.1
            }

            return result
        }
        switch mode {
        case .record:
            errors.append(SnapshotError.recordModeEnabled)
            for error in errors {
                guard let error = error else { continue }
                XCTFail(error.localizedErrorDescription, file: file, line: line)
            }
        case .verify:
            Xct.assertEqual(
                errors.map { ($0 as? SnapshotError)?.kind.rawValue ?? $0?.localizedErrorDescription },
                expected.map { $0?.rawValue },
                "Caught test errors must match expected",
                file: file,
                line: line
            )
        }
    }
}

// MARK: - SwiftUI

extension Xct {
    /// Версия ``Xct.snapshotAsync()`` для ``SwiftUI.View``
    public static func snapshotAsync(
        testName: String = #function,
        file: StaticString = #filePath,
        line: UInt = #line,
        matcher: SnapshotMatcherKind = .default,
        mode: SnapshotMode = .verify,
        deviceGroup: SnapshotDeviceGroup = .phone,
        includeAccessibility: Bool = false,
        prepareSut: @MainActor @escaping (SnapshotDevice) throws -> some SwiftUI.View
    ) async {
        await Xct.snapshotAsync(
            testName: testName,
            file: file,
            line: line,
            matcher: matcher,
            mode: mode,
            deviceGroup: deviceGroup,
            includeAccessibility: includeAccessibility,
            prepareSut: { device in
                try prepareSut(device).snapshotSut()
            }
        )
    }
}

// MARK: - Helpers

extension SnapshotMode {
    @MainActor
    fileprivate func prepareSnapshotView(
        device: SnapshotDevice,
        prepareReference: @MainActor @escaping (SnapshotDevice) throws -> SnapshotSut,
        prepareSut: @MainActor @escaping (SnapshotDevice) throws -> SnapshotSut
    ) throws -> SnapshotSut {
        switch self {
        case .record:
            try prepareReference(device)
        case .verify:
            try prepareSut(device)
        }
    }
}
