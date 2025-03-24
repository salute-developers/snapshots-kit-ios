import CoreGraphics

extension CGRect {
    public var center: CGPoint {
        get { CGPoint(x: midX, y: midY) }
        mutating set {
            origin.x = newValue.x - size.width / 2
            origin.y = newValue.y - size.height / 2
        }
    }

    /// Проверяет `origin` и `size` на конечность.
    public var isFinite: Bool {
        origin.x.isFinite &&
            origin.y.isFinite &&
            size.width.isFinite &&
            size.height.isFinite
    }

    public init(
        x: CGFloat,
        y: CGFloat,
        size: CGSize
    ) {
        self.init(
            x: x,
            y: y,
            width: size.width,
            height: size.height
        )
    }

    public init(
        origin: CGPoint,
        width: CGFloat,
        height: CGFloat
    ) {
        self.init(
            x: origin.x,
            y: origin.y,
            width: width,
            height: height
        )
    }

    public init(center: CGPoint, size: CGSize) {
        // TODO: Добавить выравнивание по пиксельной сетке
        let x = center.x - size.width * 0.5
        let y = center.y - size.height * 0.5
        self.init(origin: .init(x: x, y: y), size: size)
    }

    public init(
        minX: CGFloat,
        minY: CGFloat,
        maxX: CGFloat,
        maxY: CGFloat
    ) {
        self.init(
            x: minX,
            y: minY,
            width: maxX - minX,
            height: maxY - minY
        )
    }

    public func relative(in bounds: CGRect) -> CGRect {
        CGRect(
            x: origin.x / bounds.width,
            y: origin.y / bounds.height,
            width: size.width / bounds.width,
            height: size.height / bounds.height
        )
    }

    public func relative(in bounds: CGSize) -> CGRect {
        relative(in: .init(origin: .zero, size: bounds))
    }
}
