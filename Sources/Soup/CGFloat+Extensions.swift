import CoreGraphics
import UIKit

extension CGFloat {
    private static var screenScale: CGFloat {
        MainActor.syncOnMain {
            UIScreen.main.scale
        }
    }

    /// Округление в большую сторону до ширины пикселя для возвращаемого значения
    /// - Parameter scale: scale factor экрана устройства
    public func roundedUpToScreenScale() -> CGFloat {
        roundedUp(to: 1.0 / Self.screenScale)
    }

    /// Округление в меньшую сторону до ширины пикселя для возвращаемого значения
    /// - Parameter scale: scale factor экрана устройства
    public func roundedDownToScreenScale() -> CGFloat {
        roundedDown(to: 1.0 / Self.screenScale)
    }

    /// Округление вверх, которое используется в лейауте
    /// - Parameter step: шаг округления
    public func roundedUp(to step: CGFloat) -> CGFloat {
        ceil(self / step) * step
    }

    /// Округление вниз, которое используется в лейауте
    /// - Parameter step: шаг округления
    public func roundedDown(to step: CGFloat) -> CGFloat {
        floor(self / step) * step
    }
}
