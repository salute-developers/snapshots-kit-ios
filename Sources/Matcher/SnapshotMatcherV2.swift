import UIKit
import XCTest

struct SnapshotMatcherV2 {
    private static let maxColorComponentDelta = 15

    private let files: SnapshotFiles
    private let mode: SnapshotMode
    private let snapshot: UIImage
    private let screen: SnapshotDevice
    private let useSmallerBitmap: Bool

    init(
        snapshot: UIImage,
        files: SnapshotFiles,
        mode: SnapshotMode,
        screen: SnapshotDevice,
        useSmallerBitmap: Bool
    ) throws {
        self.snapshot = try files.formatSnapshot(snapshot)
        self.files = files
        self.mode = mode
        self.screen = screen
        self.useSmallerBitmap = useSmallerBitmap
    }

    func run() throws {
        switch mode {
        case let .record(onlyChanged, removeDiff):
            return try record(onlyChanged: onlyChanged, removeDiff: removeDiff)
        case .verify:
            return try verify()
        }
    }

    private func record(onlyChanged: Bool, removeDiff: Bool) throws {
        if onlyChanged {
            do {
                try verify()
            } catch {
                try files.recordReference(snapshot)
            }
        } else {
            try files.recordReference(snapshot)
        }

        if removeDiff {
            try files.removeDiff()
        }
    }

    private func verify() throws {
        let referenceData = try Data(contentsOf: files.reference)
        guard let reference = UIImage(data: referenceData, scale: screen.scale) else {
            throw SnapshotError.couldNotBeCreatedWithData
        }

        let (isEqual, pixelRatio) = try compare(snapshot, reference)

        if isEqual {
            /// Подчищаем от прошлого прогона, если остались
            try files.removeDiff()
        } else {
            try files.recordDiff(snapshot, reference)
            throw SnapshotError.comparingFailed(
                diffFilePath: files.diff.path,
                pixelRaio: pixelRatio
            )
        }
    }

    private func compare(_ snapshot: UIImage, _ reference: UIImage) throws -> (isEqual: Bool, pixelRatio: Double) {
        guard snapshot.size == reference.size,
              let snapshotCGImage = snapshot.cgImage,
              let referenceCGImage = reference.cgImage
        else {
            return (false, 0)
        }

        guard snapshotCGImage.bitsPerPixel == referenceCGImage.bitsPerPixel else {
            throw SnapshotError.differentComparingImages
        }
        guard snapshotCGImage.bitsPerPixel / 8 == 4 else {
            throw SnapshotError.unexpectedColorComponentsCount
        }

        // Рассчитываем bitmap в размерах UIImage.size (points) или в реальном размере (pixels)?
        // Реальный размер == pointsSize * scale
        let bitmapSize = useSmallerBitmap ? snapshot.size : snapshotCGImage.size

        let diff = try countPixelsWithDifferentRGBA(
            snapshotCGImage.pixelColorBytesVector(bitmapSize),
            referenceCGImage.pixelColorBytesVector(bitmapSize)
        )
        let ratio = Double(diff) / Double(bitmapSize.width * bitmapSize.height)
        return (diff == 0, ratio)
    }

    private func countPixelsWithDifferentRGBA(_ lhs: [UInt8], _ rhs: [UInt8]) throws -> Int {
        let bytesPerPixel = 4

        guard lhs.count == rhs.count, lhs.count % bytesPerPixel == 0 else {
            throw SnapshotError.differentBytesPerPixel
        }

        var changed = 0
        var componentNumber = 0 // 1...4 - color part, 0 - unset
        var index = 0

        while index < lhs.count {
            componentNumber += 1

            let left = lhs[index]
            let right = rhs[index]
            // Разница между компонентой цвета пикселя (абсолют, >= 0)
            let diff = left > right ? left - right : right - left

            if diff > Self.maxColorComponentDelta {
                changed += 1
                let nextColorShift = bytesPerPixel - componentNumber + 1
                index += nextColorShift
                componentNumber = 0
                continue
            }

            if componentNumber == bytesPerPixel {
                // moving to next color
                componentNumber = 0
            }
            index += 1
        }

        return changed
    }
}
