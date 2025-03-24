extension Result {
    public var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }

    public var isFailure: Bool {
        if case .failure = self {
            return true
        }
        return false
    }

    public var success: Success? {
        guard case let .success(wrapped) = self else { return nil }

        return wrapped
    }

    public var error: Failure? {
        guard case let .failure(error) = self else { return nil }

        return error
    }
}

extension Result where Success == Void {
    public static var success: Result {
        .success(())
    }
}

extension Result {
    public init(catchingAsync body: () async throws(Failure) -> Success) async {
        do {
            self = .success(try await body())
        } catch {
            self = .failure(error)
        }
    }
}
