import SwiftUI
import UIKit

final class SnapshotSutChecker: @unchecked Sendable {
    /// Have to hold all the suts to avoid ID collision
    private var suts: [SnapshotSut] = []
    private var seenIDs: Set<ObjectIdentifier> = []

    var isFailed: Bool { suts.count != seenIDs.count }

    @MainActor
    func check(_ snapshotSut: SnapshotSut) throws {
        let sut: SnapshotSut = switch snapshotSut {
        case let holder as SnapshotSutHolder: holder.subject
        default: snapshotSut
        }

        suts.append(sut)
        let id = ObjectIdentifier(sut as AnyObject)
        if !seenIDs.insert(id).inserted {
            throw SnapshotError.sutHasBeenReused
        }
    }
}
