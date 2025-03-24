import CoreGraphics

extension CGImage {
    private static let snapshotColorSpace = CGColorSpaceCreateDeviceRGB()

    var size: CGSize {
        CGSize(width: width, height: height)
    }

    /// Вектор из RGBA компонент (значения в 0...255) по каждому __pixel__ (конкатенация по строкам)
    func pixelColorBytesVector(_ size: CGSize) -> [UInt8] {
        let integralWidth = Int(size.width)
        let integralHeight = Int(size.height)
        let context = CGContext(
            data: nil,
            width: integralWidth,
            height: integralHeight,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: Self.snapshotColorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        context?.draw(self, in: CGRect(origin: .zero, size: size))
        guard let data = context?.data else {
            return []
        }
        let dataPtr = data.assumingMemoryBound(to: UInt8.self)
        let capacity = bytesPerRow * integralHeight
        let bytes = Array(UnsafeBufferPointer(start: dataPtr, count: capacity))
        let colorComponentsCount = 4 // RGBA, bitsPerPixel / 8
        /// bytesPerRow включает байты дополнительной информации в конце каждой строки
        /// Вычисляем кол-во байтов цветовых компонент на строку
        let colorBytesPerRow = integralWidth * colorComponentsCount

        var bytesWithoutPadding = [UInt8]()
        bytesWithoutPadding.reserveCapacity(colorBytesPerRow * integralHeight)

        for rowIndex in 0 ..< integralHeight {
            let fromIdx = rowIndex * bytesPerRow
            let toIdx = fromIdx + colorBytesPerRow
            bytesWithoutPadding.append(contentsOf: bytes[fromIdx ..< toIdx])
        }
        return bytesWithoutPadding
    }
}
