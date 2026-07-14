import Foundation

private struct PreviewArtworkLoader: RemoteArtworkLoading {
    func data(for url: URL) async throws -> Data {
        throw URLError(.resourceUnavailable)
    }

    func cachedData(for url: URL) -> Data? {
        nil
    }

    func prewarm(_ urls: [URL]) async {}
}

func makePreviewArtworkLoader() -> some RemoteArtworkLoading {
    PreviewArtworkLoader()
}
