import UIKit

/// "Холст" для съемки снепшота, описывает параметры целевого устройства.
/// Определяет size, scale, safeArea и включен ли crop по sut.frame
public struct SnapshotDevice: Configurable, Sendable {
    private var safeArea: SafeAreaInsets

    public let scale: CGFloat
    /// Orientation based size
    public private(set) var size: CGSize

    public var orientation: Orientation {
        didSet {
            if orientation != oldValue {
                size = size.flipped()
            }
        }
    }

    /// Orientation based safe area insets
    public var insets: UIEdgeInsets {
        safeArea.insets(orientation: orientation)
    }

    /// Apply specified safe area (or set it to .zero)
    public var isSafeAreaOn: Bool {
        get { safeArea.isOn }
        set { safeArea.isOn = newValue }
    }

    /// Crop snapshot to sut view frame (use full screen size instead if turned off)
    public var isCropOn: Bool

    init(
        portraitWidth: CGFloat,
        portraitHeight: CGFloat,
        scale: CGFloat,
        portraitSafeArea: UIEdgeInsets,
        landscapeSafeArea: UIEdgeInsets,
        orientation: Orientation,
        isCropOn: Bool = false
    ) {
        let size = CGSize(width: portraitWidth, height: portraitHeight)
        switch orientation {
        case .portrait:
            self.size = size
        case .landscape:
            self.size = size.flipped()
        }

        self.scale = scale
        self.safeArea = SafeAreaInsets(
            portrait: portraitSafeArea,
            landscape: landscapeSafeArea,
            isOn: portraitSafeArea != .zero || landscapeSafeArea != .zero
        )
        self.orientation = orientation
        self.isCropOn = isCropOn
    }

    mutating func flip() {
        switch orientation {
        case .portrait:
            orientation = .landscape
        case .landscape:
            orientation = .portrait
        }
    }

    func referenceURL(testName: String, suffix: String, testFile: StaticString) -> URL {
        let name = testName
            .replacingOccurrences(of: "test_", with: "")
            .replacingOccurrences(of: "()", with: "")
            .appending(suffix)

        return URL(
            fileURLWithPath: "\(testFile)",
            isDirectory: true
        )
        .deletingLastPathComponent()
        .appendingPathComponent("_Snapshots_", isDirectory: true)
        .appendingPathComponent("\(name)_\(Int(size.width))x\(Int(size.height))@\(Int(scale))x.png")
    }
}

extension SnapshotDevice {
    public enum Orientation: String, Sendable {
        case landscape
        case portrait
    }

    struct SafeAreaInsets: Sendable {
        let portrait: UIEdgeInsets
        let landscape: UIEdgeInsets
        var isOn: Bool

        init(
            portrait: UIEdgeInsets,
            landscape: UIEdgeInsets,
            isOn: Bool
        ) {
            self.portrait = portrait
            self.landscape = landscape
            self.isOn = isOn
        }

        func insets(orientation: Orientation) -> UIEdgeInsets {
            guard isOn else { return .zero }

            switch orientation {
            case .portrait: return portrait
            case .landscape: return landscape
            }
        }
    }
}

extension SnapshotDevice {
    var specText: String {
        let insets = self.insets
        return """
        	Size: \(size)
        	Insets: [
        		top: \(insets.top)
        		left: \(insets.left)
        		right: \(insets.right)
        		bottom: \(insets.bottom)
        	]
        	Orientation: \(orientation)
        """
    }

    var attachmentDescription: String {
        """
        Orientation: \(orientation.rawValue) \
        Size: w: \(size.width) h: \(size.height)
        """
    }
}

extension CGSize {
    fileprivate func flipped() -> CGSize {
        CGSize(width: height, height: width)
    }
}
