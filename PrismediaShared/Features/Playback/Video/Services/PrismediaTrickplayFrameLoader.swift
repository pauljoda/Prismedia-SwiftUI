import Foundation

struct PrismediaTrickplayFrameLoader: TrickplayFrameLoading {
    private let client: PrismediaAPIClient

    init(client: PrismediaAPIClient) {
        self.client = client
    }

    func loadFrames(playlistPath: String) async -> [TrickplayPlaylist.Frame] {
        do {
            let data = try await client.mediaData(for: playlistPath)
            guard
                let contents = String(data: data, encoding: .utf8),
                let playlistURL = client.authenticatedMediaURL(for: playlistPath)
            else {
                return []
            }
            let playlist = try TrickplayPlaylist.parse(
                contents: contents,
                playlistURL: playlistURL
            )
            guard !Task.isCancelled else { return [] }
            return playlist.frames.map(authenticatedFrame)
        } catch {
            return []
        }
    }

    private func authenticatedFrame(
        _ frame: TrickplayPlaylist.Frame
    ) -> TrickplayPlaylist.Frame {
        TrickplayPlaylist.Frame(
            startTime: frame.startTime,
            imageURL: client.authenticatedMediaURL(for: frame.imageURL.absoluteString)
                ?? frame.imageURL,
            crop: frame.crop,
            imageWidth: frame.imageWidth,
            imageHeight: frame.imageHeight
        )
    }
}
