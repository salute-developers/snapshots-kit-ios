import Foundation
import UIKit

/// Расширение CGSize
extension CGSize {
    public init(square: CGFloat) {
        self.init(width: square, height: square)
    }

    /// Размер с бесконечной шириной и высотой
    public static var infinity: CGSize {
        CGSize(width: CGFloat.infinity, height: CGFloat.infinity)
    }

    /// Минимальный из ширины и высоты размер
    @inlinable public var minDimension: CGFloat {
        min(width, height)
    }

    /// Максимальный из ширины и высоты размер
    @inlinable public var maxDimension: CGFloat {
        max(width, height)
    }

    /// Площадь прямоугольника
    @inlinable public var area: CGFloat {
        width * height
    }

    /// Возвращает абсолютный размер (с положительными значениями)
    @inlinable public var absolute: CGSize {
        CGSize(
            width: abs(width),
            height: abs(height)
        )
    }

    /// Возможность складывать две CGSize (w+w, h+h)
    ///
    /// - Parameters:
    ///   - left: CGSize
    ///   - right: CGSize
    /// - Returns: сумма двух CGSize
    public static func + (left: CGSize, right: CGSize) -> CGSize {
        CGSize(
            width: left.width + right.width,
            height: left.height + right.height
        )
    }

    /// Округляет до ближайшего целого w и h размер
    ///
    /// - Parameter size: CGSize
    /// - Returns: CGSize с округленными width и height
    public static func ceil(_ size: CGSize) -> CGSize {
        CGSize(width: Darwin.ceil(size.width), height: Darwin.ceil(size.height))
    }

    /// Округлённый до ближайшего целого w и h размер
    public var ceiled: CGSize { Self.ceil(self) }

    /// Возможность складывать CGSize и UIEdgeInsets:
    /// ширина и горизонтальные отступы (слева и справа), высота и вертикальные отступы (сверху и снизу)
    ///
    /// - Parameters:
    ///   - left: CGSize
    ///   - right: UIEdgeInsets
    /// - Returns: CGSize, у которой ширина и высота увеличены на вертикальные и горизонтальные отступы
    public static func + (_ left: CGSize, _ right: UIEdgeInsets) -> CGSize {
        CGSize(
            width: left.width + right.horizontalInsetsSum,
            height: left.height + right.verticalInsetsSum
        )
    }

    /// Возможность умножать CGSize и CGFloat
    ///
    /// - Parameters:
    ///   - size: CGSize
    ///   - scalar: Число
    /// - Returns: CGSize умноженное на число
    public static func * (_ size: CGSize, _ scalar: CGFloat) -> CGSize {
        CGSize(
            width: scalar * size.width,
            height: scalar * size.height
        )
    }

    /// Изменяет размер на указанные отступы.
    ///
    /// - Parameter insets: Отступы, которые будут применены к размеру.
    /// - Returns: Измененный размер.
    public func inset(by insets: UIEdgeInsets) -> CGSize {
        let preferredWidth = width - insets.horizontalInsetsSum
        let preferredHeight = height - insets.verticalInsetsSum

        return CGSize(
            width: max(0, preferredWidth),
            height: max(0, preferredHeight)
        )
    }

    /// Центрирует объект заданного размера в прямоугольнике.
    ///
    /// - Parameter rect: Прямогольник относитльно которого происходит центрирование.
    /// - Returns: Прямоуголинк с нужным размером центрированный относительного заданнного.
    public func centered(in rect: CGRect) -> CGRect {
        CGRect(
            x: rect.midX - self.width / 2,
            y: rect.midY - self.height / 2,
            size: self
        )
    }

    /// Вписывает этот размер в другой размер `size`
    /// - Returns: Вписанный размер
    public func aspectFit(in size: CGSize) -> CGSize {
        guard width > 0, height > 0 else {
            return .zero
        }

        let factor = min(size.width / width, size.height / height)
        return CGSize(width: width * factor, height: height * factor)
    }

    /// Пропорционально изменяет размер, чтобы полностью заполнить другой размер `size`
    public func aspectFill(size: CGSize) -> CGSize {
        guard size.width > 0, size.height > 0, width > 0, height > 0 else { return .zero }

        let factor = min(width / size.width, height / size.height)
        return CGSize(width: width / factor, height: height / factor)
    }

    /// `True` в случае если `все` компоненты этого размера примерно больше чем соответсвующие
    /// компоненты  размера `size`
    public func isAlmostGreater(_ size: CGSize) -> Bool {
        width.isAlmostGreater(size.width) && height.isAlmostGreater(size.height)
    }

    /// `True` в случае если `все` компоненты этого размера примерно равны соответсвующим
    /// компонентам  размера `size`
    public func isAlmostEqual(_ size: CGSize) -> Bool {
        width.isAlmostEqual(size.width) && height.isAlmostEqual(size.height)
    }

    public func clamp(to size: CGSize) -> CGSize {
        CGSize(
            width: min(width, size.width),
            height: min(height, size.height)
        )
    }
}

extension CGSize: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(width)
        hasher.combine(height)
    }
}
