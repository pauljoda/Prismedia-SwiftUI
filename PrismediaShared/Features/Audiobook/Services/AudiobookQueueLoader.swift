import Foundation

struct AudiobookQueueLoader: Sendable {
    private let detailLoader: any EntityDetailLoading

    init(detailLoader: any EntityDetailLoading) {
        self.detailLoader = detailLoader
    }

    func load(detail: EntityDetail) async -> AudiobookPlaybackProjection? {
        guard let projection = AudiobookPlaybackProjection(detail: detail) else { return nil }

        let durations = await withTaskGroup(of: (UUID, Double?).self) { group in
            for track in projection.tracks {
                group.addTask {
                    let detail = try? await detailLoader.loadEntity(id: track.id)
                    let duration = detail?.capabilities.lazy.compactMap { capability -> String? in
                        guard case .technical(let technical) = capability else { return nil }
                        return technical.duration
                    }.first.flatMap(AudiobookDurationParser.seconds)
                    return (track.id, duration)
                }
            }

            var values: [UUID: Double] = [:]
            for await (id, duration) in group {
                if let duration { values[id] = duration }
            }
            return values
        }

        let hydratedTracks = projection.tracks.map { track in
            guard let duration = durations[track.id] else { return track }
            return MusicTrack(
                id: track.id,
                title: track.title,
                artist: track.artist,
                album: track.album,
                artworkPath: track.artworkPath,
                duration: duration,
                discNumber: track.discNumber,
                discTitle: track.discTitle,
                trackNumber: track.trackNumber,
                sortOrder: track.sortOrder
            )
        }
        return AudiobookPlaybackProjection(
            bookID: projection.bookID,
            title: projection.title,
            tracks: hydratedTracks
        )
    }
}
