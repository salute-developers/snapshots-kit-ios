import Foundation

extension MainActor {
    /// Выполнить синхронно операцию на Thread.main
    ///
    /// Если вызов на main – используем MainActor.assumeIsolated() с синхронным выполнением
    ///
    /// Если вызов вне main – используем DispatchQueue.main.sync() с приостановкой потока
    public static func syncOnMain<T>(_ block: @MainActor () throws -> T) rethrows -> T where T: Sendable {
        if Thread.isMainThread {
            return try MainActor.assumeIsolated(block)
        } else {
            return try DispatchQueue.main.sync(execute: block)
        }
    }
}
