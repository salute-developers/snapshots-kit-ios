import Foundation

/// Расширение над плавающей точкой, добавляющее операции сравнения с погрешностью
extension FloatingPoint where Self.Stride: ExpressibleByFloatLiteral {
    public static var accuracy: Self.Stride { 1E-8 }

    @inlinable
    public func isAlmostGreater(_ number: Self, accuracy: Self.Stride = Self.accuracy) -> Bool {
        number.distance(to: self) > accuracy
    }

    @inlinable
    public func isAlmostGreaterOrEqual(_ number: Self, accuracy: Self.Stride = Self.accuracy) -> Bool {
        isAlmostEqual(number, accuracy: accuracy) || isAlmostGreater(number, accuracy: accuracy)
    }

    @inlinable
    public func isAlmostLess(_ number: Self, accuracy: Self.Stride = Self.accuracy) -> Bool {
        number.distance(to: self) < -accuracy
    }

    @inlinable
    public func isAlmostLessOrEqual(_ number: Self, accuracy: Self.Stride = Self.accuracy) -> Bool {
        isAlmostEqual(number, accuracy: accuracy) || isAlmostLess(number, accuracy: accuracy)
    }

    @inlinable
    public func isAlmostEqual(_ number: Self, accuracy: Self.Stride = Self.accuracy) -> Bool {
        abs(number.distance(to: self)) <= accuracy
    }
}
