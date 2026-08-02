#if os(iOS) || os(macOS)
    import Foundation

    @MainActor
    final class MusicPlaybackServiceRelay: MusicPlaybackServicing {
        private var service: (any MusicPlaybackServicing)?

        func connect(to service: any MusicPlaybackServicing) {
            self.service = service
        }

        func disconnect() {
            service = nil
        }

        var isPlaybackAvailable: Bool { service != nil }

        func audioStreamURL(for trackID: UUID) -> URL? {
            service?.audioStreamURL(for: trackID)
        }

        func artworkURL(for path: String?) -> URL? {
            service?.artworkURL(for: path)
        }

        func recordEntityConsumptionEvent(
            id: UUID,
            kind: ConsumptionEventKind,
            positionSeconds: Double?,
            durationSeconds: Double?,
            sessionID: String?
        ) async throws {
            try await service?.recordEntityConsumptionEvent(
                id: id,
                kind: kind,
                positionSeconds: positionSeconds,
                durationSeconds: durationSeconds,
                sessionID: sessionID
            )
        }

        func updateEntityConsumption(
            id: UUID,
            positionSeconds: Double?,
            activitySeconds: Double?,
            completed: Bool?
        ) async throws {
            try await service?.updateEntityConsumption(
                id: id,
                positionSeconds: positionSeconds,
                activitySeconds: activitySeconds,
                completed: completed
            )
        }

        func reportEntityProgress(id: UUID, request: EntityProgressUpdateRequest) async throws {
            try await service?.reportEntityProgress(id: id, request: request)
        }
    }
#endif
