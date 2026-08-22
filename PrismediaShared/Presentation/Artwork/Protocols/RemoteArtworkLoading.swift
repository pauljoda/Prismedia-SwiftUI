import CoreGraphics
import Foundation

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
