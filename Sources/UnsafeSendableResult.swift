import Foundation

final class UnsafeSendableResult<T>: @unchecked Sendable {
    let group = DispatchGroup()
    var subject: Result<T, Error>!

    func catching(_ work: () async throws -> T) async {
        do {
            let result = try await work()
            subject = .success(result)
        } catch {
            subject = .failure(error)
        }
    }
}
