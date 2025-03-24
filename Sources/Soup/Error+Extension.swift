import Foundation

extension Error {
    /// Возвращает `errorDescription` при наличии, иначе `localizedDescription`
    public var localizedErrorDescription: String {
        if let localized = self as? LocalizedError {
            return localized.errorDescription ?? localized.localizedDescription
        } else {
            return localizedDescription
        }
    }

    public var nsCode: Int {
        (self as NSError).code
    }

    public var nsDomain: String {
        (self as NSError).domain
    }
}
