import UIKit

/// Расширение интерфейса UIViewController упрощающее работу
/// по добавлению/удалению дочерних View-контроллеров.
extension UIViewController {
    /// Добавление дочернего контроллера и его View на родительский контроллер.
    ///
    /// - Parameter child: Дочерний контроллер для добавления.
    /// - Parameter subview: Опциональная дочерняя Subview,
    /// в которую будет добавлена View child-контроллера.
    /// Если subview == nil, то добавляем на view родителя.
    public func add(
        _ child: UIViewController,
        in subview: UIView? = nil
    ) {
        let container: UIView = subview ?? view
        addChild(child)
        container.addSubview(child.view)
        child.didMove(toParent: self)
    }

    /// Удаление контроллера из иерархии родительского контроллера, если такой имеется.
    public func remove() {
        guard parent != nil else { return }

        willMove(toParent: nil)
        removeFromParent()
        viewIfLoaded?.removeFromSuperview()
        didMove(toParent: nil)
    }
}
