#if os(iOS) || os(macOS)
    import Foundation

    @MainActor
    final class MusicPlaybackServiceRelay: MusicPlaybackServicing {
        private var service: (any MusicPlaybackServicing)?

        func connect(to service: any MusicPlaybackServicing) {
            self.service = service
        }

        func audioStreamURL(for trackID: UUID) -> URL? {
            service?.audioStreamURL(for: trackID)
        }

        func recordAudioTrackPlay(id: UUID) async throws {
            try await service?.recordAudioTrackPlay(id: id)
        }

        func updateEntityPlayback(id: UUID, resumeSeconds: Double, completed: Bool) async throws {
            try await service?.updateEntityPlayback(
                id: id,
                resumeSeconds: resumeSeconds,
                completed: completed
            )
        }
    }
#endif
