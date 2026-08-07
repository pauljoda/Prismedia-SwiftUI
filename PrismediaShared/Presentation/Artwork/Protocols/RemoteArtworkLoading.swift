import CoreGraphics
import Foundation
import ImageIO

#if os(macOS)
    import AppKit
#else
    import UIKit
#endif

public protocol RemoteArtworkLoading: Sendable {
    func data(for url: URL) async throws -> Data
    func cachedData(for url: URL) -> Data?
    func image(for url: URL, maxPixelSize: Int) async throws -> CGImage
    func cachedImage(for url: URL, maxPixelSize: Int) -> CGImage?
    func prewarm(_ urls: [URL]) async
    func clearCache() async
}

extension RemoteArtworkLoading {
    public func image(for url: URL, maxPixelSize: Int) async throws -> CGImage {
        let data = try await data(for: url)
        return try await Task.detached(priority: .userInitiated) {
            try downsampleRemoteArtworkImage(data, maxPixelSize: maxPixelSize)
        }.value
    }

    public func cachedImage(for url: URL, maxPixelSize: Int) -> CGImage? {
        nil
    }

    public func clearCache() async {}
}

func downsampleRemoteArtworkImage(_ data: Data, maxPixelSize: Int) throws -> CGImage {
    if let source = CGImageSourceCreateWithData(data as CFData, nil) {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: max(1, maxPixelSize),
        ]
        if let image = CGImageSourceCreateThumbnailAtIndex(
            source,
            0,
            options as CFDictionary
        ) {
            return image
        }
    }

    if let platformImage = renderPlatformArtworkImage(
        data,
        maxPixelSize: max(1, maxPixelSize)
    ) {
        return platformImage
    }

    throw URLError(.cannotDecodeContentData)
}

private func scaledArtworkSize(_ size: CGSize, maxPixelSize: Int) -> CGSize? {
    guard size.width > 0, size.height > 0 else { return nil }
    let scale = CGFloat(maxPixelSize) / max(size.width, size.height)
    return CGSize(
        width: max(1, (size.width * scale).rounded()),
        height: max(1, (size.height * scale).rounded())
    )
}

#if os(macOS)
    private func renderPlatformArtworkImage(_ data: Data, maxPixelSize: Int) -> CGImage? {
        guard
            let image = NSImage(data: data),
            let targetSize = scaledArtworkSize(image.size, maxPixelSize: maxPixelSize),
            let bitmap = NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: Int(targetSize.width),
                pixelsHigh: Int(targetSize.height),
                bitsPerSample: 8,
                samplesPerPixel: 4,
                hasAlpha: true,
                isPlanar: false,
                colorSpaceName: .deviceRGB,
                bytesPerRow: 0,
                bitsPerPixel: 0
            ),
            let context = NSGraphicsContext(bitmapImageRep: bitmap)
        else { return nil }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        context.imageInterpolation = .high
        image.draw(
            in: CGRect(origin: .zero, size: targetSize),
            from: .zero,
            operation: .copy,
            fraction: 1
        )
        context.flushGraphics()
        NSGraphicsContext.restoreGraphicsState()
        return bitmap.cgImage
    }
#else
    private func renderPlatformArtworkImage(_ data: Data, maxPixelSize: Int) -> CGImage? {
        guard
            let image = UIImage(data: data),
            let targetSize = scaledArtworkSize(image.size, maxPixelSize: maxPixelSize)
        else { return nil }

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let rendered = UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return rendered.cgImage
    }
#endif
