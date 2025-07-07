import UIKit

public struct SnapshotSimulator: Equatable, Sendable {
    public let deviceVersion: String
    public let osVersion: OperatingSystemVersion
    
    public init(deviceVersion: String, osVersion: OperatingSystemVersion) {
        self.deviceVersion = deviceVersion
        self.osVersion = osVersion
    }
}
