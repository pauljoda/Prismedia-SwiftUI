import Foundation
import ImageIO

enum EntityMediaFeedIntrinsicAspectRatio {
    nonisolated static func resolve(data: Data) -> Double? {
        guard
            let source = CGImageSourceCreateWithData(data as CFData, nil),
            let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
                as? [CFString: Any],
            let width = (properties[kCGImagePropertyPixelWidth] as? NSNumber)?.doubleValue,
            let height = (properties[kCGImagePropertyPixelHeight] as? NSNumber)?.doubleValue,
            width.isFinite,
            height.isFinite,
            width > 0,
            height > 0
        else { return nil }

        let orientation = (properties[kCGImagePropertyOrientation] as? NSNumber)?.intValue
        if let orientation, 5...8 ~= orientation {
            return height / width
        }
        return width / height
    }
}
