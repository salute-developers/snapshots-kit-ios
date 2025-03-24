enum SnapshotKind {
    case interface
    case accessibility

    var referenceFileSuffix: String {
        switch self {
        case .interface:
            return ""
        case .accessibility:
            return "_Accessibility"
        }
    }
}
