import UIKit

/// Группа девайсов для съемки snapshot.
/// Добавляют вспомогательные декларативные методы для подготовки `[SnapshotDevice]`
public struct SnapshotDeviceGroup: Sendable {
    public let devices: [SnapshotDevice]

    /// Возможен ли поворот девайсов группы? Имеет ли смысл?
    ///
    /// Например поворот холста под Split View не создает реально возможный вариант полотна для верстки
    ///
    /// - Important: false отключает эффект модификаторов смены ориентации
    public let rotatable: Bool

    public init(
        rotatable: Bool,
        _ devices: [SnapshotDevice]
    ) {
        self.rotatable = rotatable
        self.devices = devices
    }

    public init(
        rotatable: Bool,
        _ devices: SnapshotDevice...
    ) {
        self.rotatable = rotatable
        self.devices = devices
    }
}

extension SnapshotDeviceGroup {
    public static func + (lhs: Self, rhs: Self) -> Self {
        SnapshotDeviceGroup(
            rotatable: lhs.rotatable && rhs.rotatable,
            lhs.devices + rhs.devices
        )
    }

    /// Отключает safeArea у всех девайсов группы
    public var noSafeArea: Self {
        SnapshotDeviceGroup(
            rotatable: rotatable,
            devices.map { $0.configure { $0.isSafeAreaOn = false } }
        )
    }

    /// Добавляет обрезку snapshot до размеров тестируемого View у всех девайсов группы
    public var cropped: Self {
        SnapshotDeviceGroup(
            rotatable: rotatable,
            devices.map { $0.configure { $0.isCropOn = true } }
        )
    }

    /// "Поворачивает" все девайсы в ландшафтный режим (горизонтальный)
    public var landscape: Self {
        guard rotatable else { return self }

        return SnapshotDeviceGroup(
            rotatable: true,
            devices.map { $0.configure { $0.orientation = .landscape } }
        )
    }

    /// Добавить копии экранов в противоположной ориентации.
    /// Позволяет сделать snapshot портрета и ландшафтного режима
    public var universal: Self {
        guard rotatable else { return self }

        return SnapshotDeviceGroup(
            rotatable: false,
            devices + devices.map { $0.configure { $0.flip() } }
        )
    }
}

extension SnapshotDeviceGroup {
    /// Произвольное поле
    ///
    /// Например для вывода набора иконок без подвязки к реальному девайсу
    ///
    /// - Note: Следует подогнать размер под минимально достаточный для View
    public static func custom(
        width: CGFloat = 375,
        height: CGFloat = 1_000,
        scale: CGFloat = 2,
        portraitSafeArea: UIEdgeInsets = .zero,
        landscapeSafeArea: UIEdgeInsets = .zero,
        isCropOn: Bool = true
    ) -> SnapshotDeviceGroup {
        SnapshotDeviceGroup(
            rotatable: true,
            SnapshotDevice(
                portraitWidth: width,
                portraitHeight: height,
                scale: scale,
                portraitSafeArea: portraitSafeArea,
                landscapeSafeArea: landscapeSafeArea,
                orientation: .portrait,
                isCropOn: isCropOn
            )
        )
    }

    /// __Портретные__ iPhone
    public static let phone = SnapshotDeviceGroup(
        rotatable: true,
        .iPhoneSE,
        .iPhone13mini
    )

    /// __Портретные__ iPad
    public static let tablet = SnapshotDeviceGroup(
        rotatable: true,
        SnapshotDevice( // iPad mini (6th generation)
            portraitWidth: 744,
            portraitHeight: 1_133,
            scale: 2,
            portraitSafeArea: .iPadMini6SafeArea,
            landscapeSafeArea: .iPadMini6SafeArea,
            orientation: .portrait
        )
    )

    /// iPad Split View, обе ориентации
    ///
    /// Замеры под iPad mini (6th generation)
    public static let tabletSplitMode = SnapshotDeviceGroup(
        rotatable: false,
        SnapshotDevice(
            portraitWidth: 320,
            portraitHeight: 1_133,
            scale: 2,
            portraitSafeArea: .iPadMini6SafeArea,
            landscapeSafeArea: .iPadMini6SafeArea,
            orientation: .portrait
        ),
        SnapshotDevice(
            portraitWidth: 414,
            portraitHeight: 1_133,
            scale: 2,
            portraitSafeArea: .iPadMini6SafeArea,
            landscapeSafeArea: .iPadMini6SafeArea,
            orientation: .portrait
        ),
        SnapshotDevice(
            portraitWidth: 375,
            portraitHeight: 744,
            scale: 2,
            portraitSafeArea: .iPadMini6SafeArea,
            landscapeSafeArea: .iPadMini6SafeArea,
            orientation: .landscape
        ),
        SnapshotDevice(
            portraitWidth: 561.5,
            portraitHeight: 744,
            scale: 2,
            portraitSafeArea: .iPadMini6SafeArea,
            landscapeSafeArea: .iPadMini6SafeArea,
            orientation: .landscape
        ),
        SnapshotDevice(
            portraitWidth: 748,
            portraitHeight: 744,
            scale: 2,
            portraitSafeArea: .iPadMini6SafeArea,
            landscapeSafeArea: .iPadMini6SafeArea,
            orientation: .landscape
        )
    )
}

extension SnapshotDevice {
    public static let iPhoneSE = SnapshotDevice( // (3rd generation)
        portraitWidth: 375,
        portraitHeight: 667,
        scale: 2,
        portraitSafeArea: UIEdgeInsets(top: 20),
        landscapeSafeArea: .zero,
        orientation: .portrait
    )

    public static let iPhone13mini = SnapshotDevice(
        portraitWidth: 375,
        portraitHeight: 812,
        scale: 3,
        portraitSafeArea: UIEdgeInsets(top: 50, bottom: 34),
        landscapeSafeArea: UIEdgeInsets(top: 0, left: 50, bottom: 21, right: 50),
        orientation: .portrait
    )
}

extension UIEdgeInsets {
    fileprivate static let iPadMini6SafeArea = UIEdgeInsets(top: 24, bottom: 20)
}
