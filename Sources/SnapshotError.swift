import CoreGraphics
import Foundation

public enum SnapshotError: Error, Equatable {
    case failedToMakeSnapshot
    case failedToMakeDiffImage(referencePath: String)
    case emptyPNGRepresentation
    case couldNotBeCreatedWithData
    case differentBytesPerPixel
    case failedToAddSuffixInImageURL
    case recordModeEnabled
    case comparingFailed(diffFilePath: String, pixelRaio: Double)
    case differentComparingImages
    case unexpectedColorComponentsCount
    case sutHasBeenReused
}

extension SnapshotError: LocalizedError {
    /// Сравнимые стабильные данные из ошибки
    ///
    /// Для тестирования возврата ожидаемых ошибок сравнения
    public enum Kind: String, Equatable {
        case failedToMakeSnapshot
        case failedToMakeDiffImage
        case emptyPNGRepresentation
        case couldNotBeCreatedWithData
        case differentBytesPerPixel
        case failedToAddSuffixInImageURL
        case recordModeEnabled
        case comparingFailed
        case differentComparingImages
        case unexpectedColorComponentsCount
        case sutHasBeenReused
    }

    public var kind: Kind {
        switch self {
        case .failedToMakeSnapshot: return .failedToMakeSnapshot
        case .failedToMakeDiffImage: return .failedToMakeDiffImage
        case .emptyPNGRepresentation: return .emptyPNGRepresentation
        case .couldNotBeCreatedWithData: return .couldNotBeCreatedWithData
        case .differentBytesPerPixel: return .differentBytesPerPixel
        case .failedToAddSuffixInImageURL: return .failedToAddSuffixInImageURL
        case .comparingFailed: return .comparingFailed
        case .recordModeEnabled: return .recordModeEnabled
        case .differentComparingImages: return .differentComparingImages
        case .unexpectedColorComponentsCount: return .unexpectedColorComponentsCount
        case .sutHasBeenReused: return .sutHasBeenReused
        }
    }

    public var errorDescription: String? {
        switch self {
        case .failedToMakeSnapshot:
            return "Failed to make snapshot"
        case let .failedToMakeDiffImage(referencePath):
            return "Failed to create diff image for \(referencePath)"
        case .emptyPNGRepresentation:
            return "UIImagePNGRepresentation returns nil"
        case .couldNotBeCreatedWithData:
            return "UIImage could not be created with data"
        case .differentBytesPerPixel:
            return "bytesPerPixel does not matches with color bytes data array count!"
        case .failedToAddSuffixInImageURL:
            return "Failed to add suffix in image URL"
        case .recordModeEnabled:
            return "Snapshot saved. Don't forget to change mode back to `verify`!"
        case let .comparingFailed(diffFilePath, pixelRatio):
            return "View snapshot is not equal to reference, changed pixel ratio: \(pixelRatio). Diff saved at \(diffFilePath)"
        case .differentComparingImages:
            return "Different comparing images"
        case .unexpectedColorComponentsCount:
            return "Expected 4 color components per pixel (RGBA) but received other"
        case .sutHasBeenReused:
            return "SnapshotSut must be uniq per each 'prepareSut' closure call!"
        }
    }
}
