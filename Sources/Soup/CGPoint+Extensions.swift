import CoreGraphics

extension CGPoint {
    public static func + (left: CGPoint, right: CGPoint) -> CGPoint {
        CGPoint(
            x: left.x + right.x,
            y: left.y + right.y
        )
    }
}
