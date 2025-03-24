import UIKit

/// Расширение UIEdgeInsets для суммирования отступов
extension UIEdgeInsets {
    /// Горизонтальные отступы: сумма левого и правого отступов
    public var horizontalInsetsSum: CGFloat { left + right }

    /// Вертикальные отступы: сумма верхнего и нижнего отступов
    public var verticalInsetsSum: CGFloat { top + bottom }

    /// Размер по горизонтальным и вертикальным инсетам
    public var insetsSum: CGSize {
        CGSize(width: horizontalInsetsSum, height: verticalInsetsSum)
    }

    public init(inset: CGFloat) {
        self.init(top: inset, left: inset, bottom: inset, right: inset)
    }

    public init(left: CGFloat, right: CGFloat) {
        self.init(top: 0, left: left, bottom: 0, right: right)
    }

    public init(top: CGFloat = 0, bottom: CGFloat = 0) {
        self.init(top: top, left: 0, bottom: bottom, right: 0)
    }

    public init(horizontal: CGFloat = 0, vertical: CGFloat = 0) {
        self.init(top: vertical, left: horizontal, bottom: vertical, right: horizontal)
    }

    public static prefix func - (insets: UIEdgeInsets) -> UIEdgeInsets {
        UIEdgeInsets(
            top: -insets.top,
            left: -insets.left,
            bottom: -insets.bottom,
            right: -insets.right
        )
    }

    public static func + (lhs: UIEdgeInsets, rhs: UIEdgeInsets) -> UIEdgeInsets {
        UIEdgeInsets(
            top: lhs.top + rhs.top,
            left: lhs.left + rhs.left,
            bottom: lhs.bottom + rhs.bottom,
            right: lhs.right + rhs.right
        )
    }

    public static func - (lhs: UIEdgeInsets, rhs: UIEdgeInsets) -> UIEdgeInsets {
        UIEdgeInsets(
            top: lhs.top - rhs.top,
            left: lhs.left - rhs.left,
            bottom: lhs.bottom - rhs.bottom,
            right: lhs.right - rhs.right
        )
    }

    public static func -= (lhs: inout UIEdgeInsets, rhs: UIEdgeInsets) {
        lhs.top -= rhs.top
        lhs.bottom -= rhs.bottom
        lhs.left -= rhs.left
        lhs.right -= rhs.right
    }

    public static func += (lhs: inout UIEdgeInsets, rhs: UIEdgeInsets) {
        lhs.top += rhs.top
        lhs.bottom += rhs.bottom
        lhs.left += rhs.left
        lhs.right += rhs.right
    }
}

extension UIEdgeInsets: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(top)
        hasher.combine(bottom)
        hasher.combine(left)
        hasher.combine(right)
    }
}
