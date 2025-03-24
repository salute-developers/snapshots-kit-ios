import UIKit

extension UIImage {
    func makePNGData() throws -> Data {
        guard let data = pngData() else {
            throw SnapshotError.emptyPNGRepresentation
        }
        return data
    }
}
