#if DEBUG
    import Foundation

    @MainActor
    struct PreviewMusicPlaybackService: MusicPlaybackServicing {
        func audioStreamURL(for trackID: UUID) -> URL? {
            URL(string: "https://preview.prismedia.local/audio/\(trackID).mp3")
        }

        func recordAudioTrackPlay(id: UUID) async throws {}

        func updateEntityPlayback(id: UUID, resumeSeconds: Double, completed: Bool) async throws {}
    }
#endif
