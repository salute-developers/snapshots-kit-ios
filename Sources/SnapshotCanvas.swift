import SwiftUI
import UIKit

/// Полотно для рендера Snapshot
///
/// Добавляет визуализацию safeArea от ``SnapshotDevice``
final class SnapshotCanvas: UIViewController {
    private let sutHolder: SnapshotSut // TODO: SDMI-1483 fix retain?
    private let sut: Sut
    private let screen: SnapshotDevice
    private let snapshotKind: SnapshotKind

    private let topInsetView = UIView()
    private let bottomInsetView = UIView()
    private let leftInsetView = UIView()
    private let rightInsetView = UIView()
    private let topInsetLabel = UILabel()
    private let bottomInsetLabel = UILabel()
    private let leftInsetLabel = UILabel()
    private let rightInsetLabel = UILabel()

    private var isSettingSafeArea = false
    private var sutSize: CGSize?

    init(
        sut: SnapshotSut,
        screen: SnapshotDevice,
        snapshotKind: SnapshotKind = .interface
    ) {
        self.sutHolder = sut
        self.sut = sut.sut
        self.screen = screen
        self.snapshotKind = snapshotKind
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        if sut.shouldMeasureBeforeAdding {
            sutSize = sut.view.sizeThatFits(screen.size)
        }

        sut.addToCanvas(self)
        [topInsetView, bottomInsetView, leftInsetView, rightInsetView].forEach {
            $0.isOpaque = false
            $0.backgroundColor = .safeAreaBorder
            view.addSubview($0)
        }
        [topInsetLabel, bottomInsetLabel, leftInsetLabel, rightInsetLabel].forEach {
            $0.textAlignment = .center
            $0.textColor = .blue
            $0.isAccessibilityElement = false
            view.addSubview($0)
        }

        /// Нам нужен `safeArea`, посчитанный по размеру `screen`
        ///
        /// Порядок рендера такой:
        /// - view.frame = screen.size // готовим frame под screen
        /// - view.drawHierarchy()
        /// - viewSafeAreaInsetsDidChange() // получаем safeArea сразу под screen, а не Simulator!
        /// - viewWillLayoutSubviews()
        /// - UIGraphicsGetImageFromCurrentImageContext()
        view.layer.contentsScale = screen.scale
        view.frame = CGRect(origin: .zero, size: screen.size)
    }

    /// ViewController нужен нам чтобы использовать safeArea.
    /// Симулятор определяет свои отступы, а мы подгоняем их под screen спеку через additional.
    /// Если view.frame залезет в пределы его safeArea,
    /// vc.originalSafeInsets заполняются в размере пересечения границы
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()

        guard !isSettingSafeArea else { return }

        isSettingSafeArea = true
        additionalSafeAreaInsets = screen.insets - originalSafeInsets
        isSettingSafeArea = false
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        sut.view.frame = CGRect(
            center: view.bounds.center,
            size: sutSize ?? sut.view.sizeThatFits(screen.size)
        )

        let safeInsets = view.safeAreaInsets
        topInsetView.frame = CGRect(
            origin: .zero,
            width: view.frame.width,
            height: safeInsets.top
        )
        bottomInsetView.frame = CGRect(
            x: 0,
            y: view.frame.maxY - safeInsets.bottom,
            width: view.frame.width,
            height: safeInsets.bottom
        )
        leftInsetView.frame = CGRect(
            x: 0,
            y: topInsetView.frame.maxY,
            width: safeInsets.left,
            height: bottomInsetView.frame.minY - topInsetView.frame.maxY
        )
        rightInsetView.frame = CGRect(
            x: topInsetView.frame.maxX - safeInsets.right,
            y: topInsetView.frame.maxY,
            width: safeInsets.right,
            height: bottomInsetView.frame.minY - topInsetView.frame.maxY
        )
        let labelSide: CGFloat = 40
        topInsetLabel.frame = CGRect(
            origin: .zero,
            width: view.bounds.width,
            height: labelSide
        )
        bottomInsetLabel.frame = CGRect(
            x: 0,
            y: view.bounds.height - labelSide,
            width: view.bounds.width,
            height: labelSide
        )
        leftInsetLabel.frame = CGRect(
            origin: .zero,
            width: labelSide,
            height: view.bounds.height
        )
        rightInsetLabel.frame = CGRect(
            x: view.bounds.width - labelSide,
            y: 0, width: labelSide,
            height: view.bounds.height
        )

        topInsetLabel.text = "\(safeInsets.top)"
        rightInsetLabel.text = "\(safeInsets.right)"
        leftInsetLabel.text = "\(safeInsets.left)"
        bottomInsetLabel.text = "\(safeInsets.bottom)"

        [topInsetLabel, bottomInsetLabel, leftInsetLabel, rightInsetLabel].forEach {
            $0.isHidden = $0.text == "0.0"
        }
    }

    // MARK: - Snapshot

    /// Рисуем иерархию canvas View
    ///
    /// - Note: subject.drawHierarchy() дает артефакты, нужно рисовать весь canvas!
    func capture() -> UIImage? {
        defer {
            sut.removeFromCanvas()
        }

        let viewToDraw: UIView
        switch snapshotKind {
        case .interface:
            viewToDraw = view
        case .accessibility:
            let window = UIWindow(frame: CGRect(origin: .zero, size: screen.size))
            let accessibilitySnapshot = AccessibilitySnapshotView(
                containedView: view,
                viewRenderingMode: .drawHierarchyInRect,
                activationPointDisplayMode: .never,
                showUserInputLabels: true
            )
            window.addSubview(accessibilitySnapshot)
            window.makeKeyAndVisible()
            try? accessibilitySnapshot.parseAccessibility(useMonochromeSnapshot: true)
            accessibilitySnapshot.sizeToFit()
            viewToDraw = accessibilitySnapshot
        }

        UIGraphicsBeginImageContextWithOptions(viewToDraw.bounds.size, false, screen.scale)
        viewToDraw.drawHierarchy(in: viewToDraw.bounds, afterScreenUpdates: true)
        let canvasSnapshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let canvasSnapshot else {
            return nil
        }

        guard screen.isCropOn, view.bounds.size != sut.view.frame.size else {
            return canvasSnapshot
        }

        let sutFrame = canvasSnapshot.frameAtScale(sut.view.frame)

        return canvasSnapshot.cgImage?.cropping(to: sutFrame).flatMap {
            UIImage(
                cgImage: $0,
                scale: canvasSnapshot.imageRendererFormat.scale,
                orientation: canvasSnapshot.imageOrientation
            )
        }
    }
}

extension UIImage {
    /// `UIImage` имеет `size` в `Point`.
    /// При переводе в `CGImage` мы переходим на пиксели.
    /// Чтобы сделать `CGImage.cropping()`, нужно указать `CGRect` в пикселях.
    fileprivate func frameAtScale(_ pointsRect: CGRect) -> CGRect {
        let scale = imageRendererFormat.scale
        return CGRect(
            x: pointsRect.origin.x * scale,
            y: pointsRect.origin.y * scale,
            width: pointsRect.size.width * scale,
            height: pointsRect.size.height * scale
        ).integral
    }
}

@MainActor
private enum Sut {
    case view(UIView)
    case controller(UIViewController)

    var view: UIView {
        switch self {
        case let .view(view): return view
        case let .controller(controller): return controller.view
        }
    }

    /// Баг в UIHostingController возвращает не верный размер после добавления в иерархию (height += safeArea.top)
    /// Кешируем для него замер заранее
    var shouldMeasureBeforeAdding: Bool {
        switch self {
        case .view:
            return false
        case let .controller(controller):
            return controller is AnyUIHostingController
        }
    }

    func addToCanvas(_ canvas: UIViewController) {
        switch self {
        case let .view(view):
            canvas.view.addSubview(view)
        case let .controller(controller):
            canvas.add(controller)
        }
    }

    func removeFromCanvas() {
        switch self {
        case let .view(view):
            view.removeFromSuperview()
        case let .controller(controller):
            controller.remove()
        }
    }
}

extension SnapshotSut {
    @MainActor
    fileprivate var sut: Sut {
        switch self {
        case let view as UIView:
            return view.firstControllerInChain.flatMap { .controller($0) } ?? .view(view)
        case let viewController as UIViewController:
            return .controller(viewController)
        case let holder as SnapshotSutHolder:
            return holder.subject.sut
        default:
            fatalError("Unknown SnapshotSut subtype: \(self)")
        }
    }
}

extension UIView {
    fileprivate var firstControllerInChain: UIViewController? {
        var current: UIResponder = self

        while let next = current.next {
            if let controller = next as? UIViewController {
                return controller
            }
            current = next
        }

        return nil
    }
}

extension UIColor {
    fileprivate static let safeAreaBorder = UIColor.pattern3Stripes(
        color1: .red,
        color2: .blue,
        color3: .yellow,
        thickness: 40,
        alpha: 0.2
    )

    private static func pattern3Stripes(
        color1: UIColor,
        color2: UIColor,
        color3: UIColor,
        thickness: CGFloat,
        alpha: CGFloat
    ) -> UIColor {
        let squareRootOfTwo: CGFloat = sqrt(2.0)
        let dim: CGFloat = 3 * thickness * squareRootOfTwo
        let width: CGFloat = dim * squareRootOfTwo

        let pattern = UIGraphicsImageRenderer(size: CGSize(square: dim)).image { context in
            context.cgContext.rotate(by: CGFloat.pi / 4)
            context.cgContext.translateBy(x: 0, y: -3 * thickness)

            let bars: [(UIColor, UIBezierPath)] = [
                (color1, UIBezierPath(rect: .init(x: 0, y: 0, width: width, height: thickness))),
                (color2, UIBezierPath(rect: .init(x: 0, y: thickness, width: width, height: thickness))),
                (color3, UIBezierPath(rect: .init(x: 0, y: 2 * thickness, width: width, height: thickness))),
            ]

            bars.forEach { $0.0.setFill(); $0.1.fill() }
            context.cgContext.translateBy(x: 0, y: 3 * thickness)
            bars.forEach { $0.0.setFill(); $0.1.fill() }
        }

        return UIColor(patternImage: pattern).withAlphaComponent(alpha)
    }
}

private protocol AnyUIHostingController {}
extension UIHostingController: AnyUIHostingController {}
