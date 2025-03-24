import Foundation
import UIKit
import XCTest

struct SnapshotFiles: Sendable {
    private nonisolated(unsafe) let fileManager: FileManager = .default
    private let screen: SnapshotDevice
    private let isComparisonFilesUseful: Bool

    private let folder: URL
    let reference: URL
    let diff: URL
    private let new: URL
    private let merge: URL

    init(
        device: SnapshotDevice,
        testName: String,
        suffix: String,
        testFile: StaticString,
        isComparisonFilesUseful: Bool
    ) throws {
        screen = device
        let referenceURL = device.referenceURL(testName: testName, suffix: suffix, testFile: testFile)
        folder = referenceURL.deletingLastPathComponent()
        reference = referenceURL
        diff = try referenceURL.addingSuffixInImageURL("diff")
        new = try referenceURL.addingSuffixInImageURL("new")
        merge = try referenceURL.addingSuffixInImageURL("merge")
        self.isComparisonFilesUseful = isComparisonFilesUseful
    }

    /// Форматируем аналогично reference (в PNG) для корректного сравнения
    func formatSnapshot(_ image: UIImage) throws -> UIImage {
        try UIImage(data: try image.makePNGData(), scale: screen.scale)
            .get(elseThrow: SnapshotError.couldNotBeCreatedWithData)
    }

    func recordReference(_ image: UIImage) throws {
        try createFolderIfMissing()
        try image.makePNGData().write(to: reference)
    }

    func removeDiff() throws {
        for path in [diff.path, new.path, merge.path] where fileManager.fileExists(atPath: path) {
            try fileManager.removeItem(atPath: path)
        }
    }

    func recordDiff(_ new: UIImage, _ reference: UIImage) throws {
        guard isComparisonFilesUseful else { return }

        guard let diff = renderDiff(new, reference) else {
            throw SnapshotError.failedToMakeDiffImage(referencePath: self.reference.absoluteString)
        }
        try createFolderIfMissing()

        let images = [reference, new, diff]
        let mergeSize = CGSize(
            width: images.reduce(into: CGFloat(0)) { $0 += $1.size.width },
            height: reference.size.height
        )
        let merge = UIGraphicsImageRenderer(size: mergeSize).image { _ in
            var shift: CGFloat = 0
            for image in images {
                image.draw(at: CGPoint(x: shift, y: 0))
                shift += image.size.width
            }
        }
        try new.makePNGData().write(to: self.new)
        try diff.makePNGData().write(to: self.diff)
        try merge.makePNGData().write(to: self.merge)
        saveXctAttachment(merge)
    }

    private func createFolderIfMissing() throws {
        if !fileManager.fileExists(atPath: folder.path) {
            try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        }
    }

    /// Не требует вызова на .main
    private func renderDiff(_ left: UIImage, _ right: UIImage) -> UIImage? {
        let size = CGSize(
            width: max(left.size.width, right.size.width),
            height: max(left.size.height, right.size.height)
        )
        UIGraphicsBeginImageContextWithOptions(size, true, screen.scale)
        right.draw(at: .zero)
        left.draw(at: .zero, blendMode: .difference, alpha: 1)
        let differenceImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return differenceImage
    }

    private func saveXctAttachment(_ image: UIImage) {
        MainActor.syncOnMain { [screen] in
            XCTContext.runActivity(named: screen.attachmentDescription) {
                $0.attach(image, "Render")
            }
        }
    }
}

extension URL {
    fileprivate func addingSuffixInImageURL(_ suffix: String) throws -> URL {
        guard let url = URL(string: absoluteString.addingSuffixInImageURL(suffix)) else {
            throw SnapshotError.failedToAddSuffixInImageURL
        }
        return url
    }
}

extension String {
    fileprivate func addingSuffixInImageURL(_ suffix: String) -> String {
        guard let splitIndex = lastIndex(of: ".") else {
            return self
        }
        return String(self[..<splitIndex]) + "_" + suffix + String(self[splitIndex...])
    }
}

extension XCTActivity {
    fileprivate func attach(_ image: UIImage, _ name: String) {
        let attachment = XCTAttachment(image: image)
        attachment.name = name
        add(attachment)
    }
}
