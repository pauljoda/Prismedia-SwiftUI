import Foundation

public actor ArtworkPalettePipeline: ArtworkPaletteLoading {
    private let artworkLoader: any RemoteArtworkLoading
    private let cacheLimit: Int
    private var cache: [URL: ArtworkPalette] = [:]
    private var cacheOrder: [URL] = []
    private var inFlight: [URL: Task<ArtworkPalette?, Never>] = [:]

    public init(
        artworkLoader: any RemoteArtworkLoading,
        cacheLimit: Int = 96
    ) {
        self.artworkLoader = artworkLoader
        self.cacheLimit = max(cacheLimit, 1)
    }

    public func palette(for url: URL) async -> ArtworkPalette? {
        if let cached = cache[url] {
            return cached
        }
        if let task = inFlight[url] {
            return await task.value
        }

        let artworkLoader = artworkLoader
        let task = Task<ArtworkPalette?, Never>(priority: .utility) {
            guard let data = try? await artworkLoader.data(for: url) else { return nil }
            return await Task.detached(priority: .utility) {
                ArtworkColorExtractor().palette(imageData: data)
            }.value
        }
        inFlight[url] = task
        let palette = await task.value
        inFlight[url] = nil
        if let palette {
            store(palette, for: url)
        }
        return palette
    }

    private func store(_ palette: ArtworkPalette, for url: URL) {
        if cache[url] == nil {
            cacheOrder.append(url)
        }
        cache[url] = palette
        while cacheOrder.count > cacheLimit {
            let evictedURL = cacheOrder.removeFirst()
            cache[evictedURL] = nil
        }
    }
}
