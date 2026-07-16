@MainActor
struct MusicQueueArtworkPreloader {
    private let playbackService: any MusicPlaybackServicing
    private let artworkLoader: any RemoteArtworkLoading

    init(
        playbackService: any MusicPlaybackServicing,
        artworkLoader: any RemoteArtworkLoading
    ) {
        self.playbackService = playbackService
        self.artworkLoader = artworkLoader
    }

    func prewarm(queue: MusicQueue) async {
        await prewarm(MusicQueueArtworkWindow.tracks(in: queue))
    }

    private func prewarm(_ tracks: [MusicTrack]) async {
        let urls = tracks.compactMap { playbackService.artworkURL(for: $0.artworkPath) }
        guard !urls.isEmpty else { return }
        await artworkLoader.prewarm(urls)
    }
}
