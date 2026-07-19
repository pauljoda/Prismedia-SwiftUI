import CoreGraphics
import Foundation
import ImageIO

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
    guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
        throw URLError(.cannotDecodeRawData)
    }
    let options: [CFString: Any] = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceShouldCacheImmediately: true,
        kCGImageSourceThumbnailMaxPixelSize: max(1, maxPixelSize),
    ]
    guard
        let image = CGImageSourceCreateThumbnailAtIndex(
            source,
            0,
            options as CFDictionary
        )
    else {
        throw URLError(.cannotDecodeContentData)
    }
    return image
}
