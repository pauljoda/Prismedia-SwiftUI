import CoreGraphics
import Foundation
import ImageIO

struct AnimatedImageSequence: @unchecked Sendable {
    let frames: [CGImage]
    let frameEndTimes: [TimeInterval]
    let duration: TimeInterval

    func frame(at elapsedTime: TimeInterval) -> CGImage? {
        guard !frames.isEmpty, duration > 0 else { return frames.first }
        let normalizedTime = elapsedTime.truncatingRemainder(dividingBy: duration)
        let index = frameEndTimes.firstIndex { normalizedTime < $0 } ?? frames.count - 1
        return frames[index]
    }

    static func decode(data: Data, maximumPixelSize: Int = 4_096) -> Self? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let count = CGImageSourceGetCount(source)
        guard count > 0 else { return nil }
        let resolvedMaximumPixelSize = AnimatedImageDecodePolicy.maximumPixelSize(
            requestedMaximumPixelSize: maximumPixelSize,
            frameCount: count
        )

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: resolvedMaximumPixelSize,
        ]
        var frames: [CGImage] = []
        var frameEndTimes: [TimeInterval] = []
        var elapsedTime: TimeInterval = 0
        for index in 0..<count {
            guard let frame = CGImageSourceCreateThumbnailAtIndex(source, index, options as CFDictionary) else {
                continue
            }
            frames.append(frame)
            elapsedTime += frameDuration(source: source, index: index)
            frameEndTimes.append(elapsedTime)
        }
        guard !frames.isEmpty else { return nil }
        return AnimatedImageSequence(
            frames: frames,
            frameEndTimes: frameEndTimes,
            duration: elapsedTime
        )
    }

    private static func frameDuration(source: CGImageSource, index: Int) -> TimeInterval {
        guard
            let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any]
        else { return 0.1 }
        let gif = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any]
        let apng = properties[kCGImagePropertyPNGDictionary] as? [CFString: Any]
        let unclamped =
            gif?[kCGImagePropertyGIFUnclampedDelayTime] as? TimeInterval
            // GIF and APNG dictionaries use the same imported string keys.
            // The APNG spellings are not exposed by every Swift SDK overlay.
            ?? apng?[kCGImagePropertyGIFUnclampedDelayTime] as? TimeInterval
        let clamped =
            gif?[kCGImagePropertyGIFDelayTime] as? TimeInterval
            ?? apng?[kCGImagePropertyGIFDelayTime] as? TimeInterval
        return max(0.02, unclamped ?? clamped ?? 0.1)
    }
}
