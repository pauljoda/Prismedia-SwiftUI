import CoreGraphics
import Foundation

public actor RemoteArtworkPipeline: RemoteArtworkLoading {
    public static let shared = RemoteArtworkPipeline()

    private let loader: any HTTPDataLoading
    nonisolated private let cache: RemoteArtworkCache
    private let imageDecoder: @Sendable (Data, Int) async throws -> CGImage
    private var inFlight: [URL: Task<Data, Error>] = [:]
    private var imageInFlight: [String: Task<CGImage, Error>] = [:]

    public init(
        loader: any HTTPDataLoading = URLSession.shared,
        cacheLimit: Int = 96,
        decodedByteCostLimit: Int = 64 * 1_024 * 1_024
    ) {
        self.loader = loader
        cache = RemoteArtworkCache(
            countLimit: cacheLimit,
            decodedByteCostLimit: decodedByteCostLimit
        )
        imageDecoder = { data, maxPixelSize in
            try await Task.detached(priority: .userInitiated) {
                try downsampleRemoteArtworkImage(data, maxPixelSize: maxPixelSize)
            }.value
        }
    }

    init(
        loader: any HTTPDataLoading,
        cacheLimit: Int,
        decodedByteCostLimit: Int,
        imageDecoder: @escaping @Sendable (Data, Int) async throws -> CGImage
    ) {
        self.loader = loader
        cache = RemoteArtworkCache(
            countLimit: cacheLimit,
            decodedByteCostLimit: decodedByteCostLimit
        )
        self.imageDecoder = imageDecoder
    }

    public func data(for url: URL) async throws -> Data {
        if let cached = cache.data(for: url) {
            return cached
        }
        if let task = inFlight[url] {
            return try await task.value
        }

        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        let loader = self.loader
        let task = Task<Data, Error> {
            let (data, response) = try await loader.data(for: request)
            if let response = response as? HTTPURLResponse,
                !(200..<300).contains(response.statusCode)
            {
                throw URLError(.badServerResponse)
            }
            return data
        }
        inFlight[url] = task

        do {
            let data = try await task.value
            cache.store(data, for: url)
            inFlight[url] = nil
            return data
        } catch {
            inFlight[url] = nil
            throw error
        }
    }

    public nonisolated func cachedData(for url: URL) -> Data? {
        cache.data(for: url)
    }

    public func image(for url: URL, maxPixelSize: Int) async throws -> CGImage {
        if let cached = cache.image(for: url, maxPixelSize: maxPixelSize) {
            return cached
        }
        let key = imageRequestKey(for: url, maxPixelSize: maxPixelSize)
        if let task = imageInFlight[key] {
            return try await task.value
        }

        let decoder = imageDecoder
        let task = Task { [self] in
            let data = try await data(for: url)
            return try await decoder(data, maxPixelSize)
        }
        imageInFlight[key] = task

        do {
            let image = try await task.value
            cache.store(image, for: url, maxPixelSize: maxPixelSize)
            imageInFlight[key] = nil
            return image
        } catch {
            imageInFlight[key] = nil
            throw error
        }
    }

    public nonisolated func cachedImage(for url: URL, maxPixelSize: Int) -> CGImage? {
        cache.image(for: url, maxPixelSize: maxPixelSize)
    }

    public func prewarm(_ urls: [URL]) async {
        await withTaskGroup(of: Void.self) { group in
            for url in urls {
                group.addTask { [self] in
                    _ = try? await data(for: url)
                }
            }
        }
    }

    private func imageRequestKey(for url: URL, maxPixelSize: Int) -> String {
        "\(maxPixelSize)|\(url.absoluteString)"
    }
}
