#if DEBUG
    import Foundation

    @MainActor
    struct PreviewMusicPlaybackService: MusicPlaybackServicing {
        func audioStreamURL(for trackID: UUID) -> URL? {
            URL(string: "https://preview.prismedia.local/audio/\(trackID).mp3")
        }

        func updateEntityConsumption(
            id: UUID,
            positionSeconds: Double?,
            activitySeconds: Double?,
            completed: Bool?
        ) async throws {}

        func reportEntityProgress(
            id: UUID,
            request: EntityProgressUpdateRequest
        ) async throws {}
    }
#endif
