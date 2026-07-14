import ImageIO
import SwiftUI

final class TrickplaySpriteImageCache: @unchecked Sendable {
    static let shared = TrickplaySpriteImageCache()
    private let cache = NSCache<NSURL, TrickplaySpriteImage>()

    private init() {
        cache.countLimit = 12
        cache.totalCostLimit = 64 * 1_024 * 1_024
    }

    func image(for url: URL, data: Data) async -> Image? {
        if let cached = cache.object(forKey: url as NSURL) {
            return Image(decorative: cached.image, scale: 1, orientation: .up)
        }

        let decoded = await Task.detached(priority: .userInitiated) { Self.decode(data) }.value
        guard let decoded else { return nil }

        let entry = TrickplaySpriteImage(image: decoded)
        let cost = decoded.bytesPerRow * decoded.height
        cache.setObject(entry, forKey: url as NSURL, cost: cost)
        return Image(decorative: decoded, scale: 1, orientation: .up)
    }

    private nonisolated static func decode(_ data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: 4_096,
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }
}
