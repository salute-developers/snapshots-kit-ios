import UIKit

extension UIViewController {
    /// Исходные системные отступы для контента `view` (очищены от `additionalSafeAreaInsets`).
    ///
    /// Может быть полезно для верстки контейнер-контроллера,
    /// добавляющего свои Bar UI поверх `сhild` экранов.
    @inlinable public var originalSafeInsets: UIEdgeInsets {
        view.safeAreaInsets - additionalSafeAreaInsets
    }

    /// Задать отступы `safeAreaInsets`.
    /// Рассчитывает `additionalSafeAreaInsets` в необходимом размере для получения целевой размерности.
    ///
    /// - Note: `nil` значения не окажут эффекта, 0 будет применен.
    @inlinable
    public func setSafeInsets(
        top: CGFloat? = nil,
        bottom: CGFloat? = nil,
        left: CGFloat? = nil,
        right: CGFloat? = nil
    ) {
        let original = originalSafeInsets
        let totalInsets = UIEdgeInsets(
            top: top ?? original.top,
            left: left ?? original.left,
            bottom: bottom ?? original.bottom,
            right: right ?? original.right
        )

        additionalSafeAreaInsets = totalInsets - originalSafeInsets
    }
}
