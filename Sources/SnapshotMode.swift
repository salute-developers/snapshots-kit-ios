/// Режим работы инструмента для снапшотов
public enum SnapshotMode: Sendable {
    /// Запись/перезапись эталонного образца
    case record(onlyChanged: Bool, removeDiff: Bool)

    /// Проверка текущего снапшота с эталонным образцом
    case verify

    public static let record: Self = .record(onlyChanged: true, removeDiff: true)
}
