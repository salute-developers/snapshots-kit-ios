import UIKit
import XCTest

struct SnapshotMatcherV4: Sendable {
    private static let bytesPerPixel = 4 // RGBA
    private static let maxColorComponentDelta = 15
    private static let colorsSliceSize = 16_000 // pixels * 4 (RGBA)

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
        guard snapshotCGImage.bitsPerPixel / 8 == Self.bytesPerPixel else {
            throw SnapshotError.unexpectedColorComponentsCount
        }

        // Рассчитываем bitmap в размерах UIImage.size (points) или в реальном размере (pixels)?
        // Реальный размер == pointsSize * scale
        let bitmapSize = useSmallerBitmap ? snapshot.size : snapshotCGImage.size

        let result = UnsafeSendableResult<(Bool, Double)>()
        result.group.enter()
        Task {
            defer { result.group.leave() }
            await result.catching {
                try await concurrentCompare(snapshotCGImage, referenceCGImage, bitmapSize)
            }
        }
        result.group.wait()

        return try result.subject.get()
    }

    private func concurrentCompare(
        _ snapshot: CGImage,
        _ reference: CGImage,
        _ bitmapSize: CGSize
    ) async throws -> (Bool, Double) {
        async let snapshotColorsAsync = Task { snapshot.pixelColorBytesVector(bitmapSize) }.value
        async let referenceColorsAsync = Task { reference.pixelColorBytesVector(bitmapSize) }.value

        let (snapshotColors, referenceColors) = await (snapshotColorsAsync, referenceColorsAsync)

        guard snapshotColors.count == referenceColors.count, snapshotColors.count % Self.bytesPerPixel == 0 else {
            throw SnapshotError.differentBytesPerPixel
        }

        let badPixels = await concurrentColorDelta(snapshotColors, referenceColors)
        let ratio = Double(badPixels) / Double(bitmapSize.width * bitmapSize.height)
        return (badPixels == 0, ratio)
    }

    private func concurrentColorDelta(_ left: [UInt8], _ right: [UInt8]) async -> Int {
        await withTaskGroup(of: Int.self) { taskGroup in
            var index = 0

            while index < left.endIndex {
                let start = index
                let end = min(index + Self.colorsSliceSize, left.endIndex)

                taskGroup.addTask {
                    countPixelsWithDifferentRGBA(left[start ..< end], right[start ..< end])
                }
                index += Self.colorsSliceSize
            }
            return await taskGroup.reduce(into: 0) {
                $0 += $1
            }
        }
    }

    private func countPixelsWithDifferentRGBA(_ left: ArraySlice<UInt8>, _ right: ArraySlice<UInt8>) -> Int {
        var changed = 0
        var componentNumber = 0 // 1...4 - color part, 0 - unset
        var index = left.startIndex

        while index < left.endIndex {
            componentNumber += 1

            let left = left[index]
            let right = right[index]
            // Разница между компонентой цвета пикселя (абсолют, >= 0)
            let diff = left > right ? left - right : right - left

            if diff > Self.maxColorComponentDelta {
                changed += 1
                let nextColorShift = Self.bytesPerPixel - componentNumber + 1
                index += nextColorShift
                componentNumber = 0
                continue
            }

            if componentNumber == Self.bytesPerPixel {
                // moving to next color
                componentNumber = 0
            }
            index += 1
        }

        return changed
    }
}
