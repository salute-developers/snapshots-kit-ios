import UIKit

/// Временная опция выбора между алгоритмами сравнения изобращений
public enum SnapshotMatcherKind: Sendable {
    /// Алгоритм "в лоб", сравниваем цвета всех пикселей
    /// - рисуем битмап в размере pointsSize (БЕЗ учета scale)
    /// - считаем delta RGBA компонент
    /// - считаем число поехавших по цвету __пикселей__ к общему числу пикселей (pointsSize)
    case pointColorDiff

    /// Вариация `pointColorDiff` (async в имплементации, но sync интерфейс)
    case pointColorDiffConcurrent

    /// Используемый во всех продуктовых тестах алгоритм
    public static var `default`: Self { .pointColorDiffConcurrent }
}

extension SnapshotMatcherKind {
    func run(
        snapshot: UIImage,
        files: SnapshotFiles,
        mode: SnapshotMode,
        screen: SnapshotDevice
    ) throws {
        switch self {
        case .pointColorDiff:
            try SnapshotMatcherV2(
                snapshot: snapshot,
                files: files,
                mode: mode,
                screen: screen,
                useSmallerBitmap: true
            ).run()
        case .pointColorDiffConcurrent:
            try SnapshotMatcherV4(
                snapshot: snapshot,
                files: files,
                mode: mode,
                screen: screen,
                useSmallerBitmap: true
            ).run()
        }
    }
}
