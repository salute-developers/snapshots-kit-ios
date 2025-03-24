import SwiftUI
import UIKit

/// Маркер типа UI элемента, к которому применим Snapshot тест
///
/// Поддерживаем UIView, UIViewController напрямую
///
/// SwiftUI.View и ViewRenderable нужно явно превращать в UIView/UIViewController
public protocol SnapshotSut {}

extension UIView: SnapshotSut {}
extension UIViewController: SnapshotSut {}

extension SwiftUI.View {
    /// Обертка для Snapshot тестирования элементов SwiftUI
    ///
    /// Помещает в UIHostingController как rootView
    ///
    /// Мы не можем поддержать работу с чистым SwiftUI.View как SnapshotSut из-за системы типов
    public func snapshotSut(backgroundColor: UIColor? = nil) -> SnapshotSut {
        let controller = UIHostingController(rootView: self)
        if let backgroundColor {
            controller.view.backgroundColor = backgroundColor
        }
        return controller
    }
}

/// Обертка для retain необходимых объектов в памяти на время прогона теста в нетипичных конфигурациях
///
/// Позволяет не потерять из памяти UIViewController
///
/// Пример:
/// ```swift
/// let screen = SheetScreenFactory(context: context, currentDeviceIsIPad: false)
///    .make(conversationWillEndSoon.asRenderingContent())
/// let view = screen.viewController.view
///    .inlineRenderable()
///    .snapshotBackground()
/// return SnapshotSutHolder(
///     subject: view.makeUIView(using: Env.context),
///     retained: [screen] // деаллоцируется до теста, если не удержать
/// )
/// ```
public struct SnapshotSutHolder: SnapshotSut {
    public var subject: SnapshotSut
    public var retained: [Any]

    public init(subject: SnapshotSut, retained: [Any]) {
        self.subject = subject
        self.retained = retained
    }
}
