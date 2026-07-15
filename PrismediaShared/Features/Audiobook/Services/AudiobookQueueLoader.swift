import Foundation

struct AudiobookQueueLoader: Sendable {
    private static let maximumConcurrentHydrations = 6

    private let detailLoader: any EntityDetailLoading

    init(detailLoader: any EntityDetailLoading) {
        self.detailLoader = detailLoader
    }

    func load(detail: EntityDetail) async -> AudiobookPlaybackProjection? {
        guard let projection = AudiobookPlaybackProjection(detail: detail) else { return nil }
        let tracksToHydrate = projection.tracks.filter { !Self.hasValidDuration($0.duration) }
        guard !tracksToHydrate.isEmpty else { return projection }

        let durations = await hydratedDurations(for: tracksToHydrate)
        let hydratedTracks = projection.tracks.map { replacingDuration(in: $0, with: durations[$0.id]) }
        return AudiobookPlaybackProjection(
            bookID: projection.bookID,
            title: projection.title,
            tracks: hydratedTracks
        )
    }

    private func hydratedDurations(for tracks: [MusicTrack]) async -> [UUID: Double] {
        await withTaskGroup(of: (UUID, Double?).self) { group in
            let initialCount = min(Self.maximumConcurrentHydrations, tracks.count)
            for track in tracks.prefix(initialCount) {
                group.addTask { await hydratedDuration(for: track) }
            }

            var durations: [UUID: Double] = [:]
            var nextIndex = initialCount
            while let (id, duration) = await group.next() {
                if let duration { durations[id] = duration }
                guard nextIndex < tracks.count else { continue }
                let track = tracks[nextIndex]
                nextIndex += 1
                group.addTask { await hydratedDuration(for: track) }
            }
            return durations
        }
    }

    private func hydratedDuration(for track: MusicTrack) async -> (UUID, Double?) {
        let detail = try? await detailLoader.loadEntity(id: track.id)
        let duration = detail?.capabilities.lazy.compactMap { capability -> String? in
            guard case .technical(let technical) = capability else { return nil }
            return technical.duration
        }.first.flatMap(AudiobookDurationParser.seconds)
        return (track.id, Self.hasValidDuration(duration) ? duration : nil)
    }

    private static func hasValidDuration(_ duration: Double?) -> Bool {
        guard let duration else { return false }
        return duration.isFinite && duration > 0
    }

    private func replacingDuration(in track: MusicTrack, with duration: Double?) -> MusicTrack {
        guard let duration else { return track }
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
}
