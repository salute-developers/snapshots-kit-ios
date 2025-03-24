import Foundation

extension Bundle {
    public func tryChild(_ name: String) -> Bundle? {
        path(
            forResource: name,
            ofType: "bundle"
        )
        .flatMap(Bundle.init)
    }

    public func childBundle(_ name: String) -> Bundle {
        guard let bundle = tryChild(name) else {
            fatalError("Ошибка в доступе к " + name + " bundle")
        }

        return bundle
    }
}
