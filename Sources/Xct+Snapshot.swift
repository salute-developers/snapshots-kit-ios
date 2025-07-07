import SwiftUI
import UIKit
import XCTest

// MARK: - Xct

extension Xct {
    /// Expected Simulator Device model and iOS version for test run.
    ///
    /// - Note: Consider setting filling in this value before all test cases execution
    nonisolated(unsafe) public static var expectedSnapshotSimulatorDevice: SnapshotSimulator?

    /// Проверка запуска теста на ожидаемой модели и версии ОС симулятора для актуальной версии монорепо.
    private static func assertEnvironmentValid(
        file: StaticString,
        line: UInt
    ) -> Bool {
        guard let expected = Xct.expectedSnapshotSimulatorDevice else {
            return true
        }
        
        let process = ProcessInfo.processInfo

        let device = process.environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "unknown"
        let iosVersion = process.operatingSystemVersion

        if device != expected.deviceVersion || iosVersion != expected.osVersion {
            let message = """
            ❌📱 Wrong iOS simulator!

            Your ENV: \(device) on \(iosVersion)
            Valid ENV: \(expected.deviceVersion) on \(expected.osVersion)

            To create valid simulator use: `x add_ios_simulator_for_tests`.

            Snapshot references are recorded with particular simulator version. Other devices break tests.
            """
            Xct.fail(message, file: file, line: line)
            return false
        }

        return true
    }

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
        guard assertEnvironmentValid(file: file, line: line) else { return }

        var snapshotKinds: [SnapshotKind] = [.interface]
        if includeAccessibility {
            snapshotKinds.append(.accessibility)
        }

        var errors = await withTaskGroup(of: Error?.self, returning: [Error].self) { group in
            let sutChecker = SnapshotSutChecker()
            for screen in deviceGroup.devices {
                for snapshotKind in snapshotKinds {
                    group.addTask {
                        do {
                            let snapshot = try await Task { @MainActor in
                                let sut = try prepareSut(screen)
                                try sutChecker.check(sut)
                                return try SnapshotCanvas(
                                    sut: sut,
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
                            try await matcher.run(
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
        guard assertEnvironmentValid(file: file, line: line) else { return }
        let sutChecker = SnapshotSutChecker()

        var errors = await withTaskGroup(of: (Int, Error?).self, returning: [Error?].self) { group in
            for index in deviceGroup.devices.indices {
                let screen = deviceGroup.devices[index]
                group.addTask {
                    do {
                        let snapshot = try await Task { @MainActor in
                            let sut = try mode.prepareSnapshotView(
                                device: screen,
                                prepareReference: prepareReference,
                                prepareSut: prepareSut
                            )
                            try sutChecker.check(sut)
                            return try SnapshotCanvas(
                                sut: sut,
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
                        try await matcher.run(
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

            var result: [Error?] = Array(repeating: nil, count: deviceGroup.devices.count)
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
            if sutChecker.isFailed {
                errors = [SnapshotError.sutHasBeenReused]
            }
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

extension OperatingSystemVersion: @retroactive Equatable {
    public static func == (lhs: OperatingSystemVersion, rhs: OperatingSystemVersion) -> Bool {
        lhs.majorVersion == rhs.majorVersion &&
            lhs.minorVersion == rhs.minorVersion &&
            lhs.patchVersion == rhs.patchVersion
    }
}
