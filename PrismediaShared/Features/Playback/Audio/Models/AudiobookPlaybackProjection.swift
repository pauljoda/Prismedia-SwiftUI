import Foundation

public struct AudiobookPlaybackProjection: Equatable, Sendable {
    public let bookID: UUID
    public let title: String
    public let tracks: [MusicTrack]

    public init(bookID: UUID, title: String, tracks: [MusicTrack]) {
        self.bookID = bookID
        self.title = title
        self.tracks = tracks.filter(\.isPlayable)
    }

    public init?(detail: EntityDetail) {
        guard detail.kind == .book else { return nil }

        let author = detail.relationships
            .first { $0.kind == .bookAuthor || $0.kind == .person }?
            .entities.first?.title
        let artwork = detail.capabilities.compactMap { capability -> EntityImagesCapability? in
            guard case .images(let images) = capability else { return nil }
            return images
        }.first.flatMap { images in
            images.items.first { ["cover", "poster", "thumbnail"].contains($0.kind) }?.path
                ?? images.coverURL
                ?? images.thumbnail2xURL
                ?? images.thumbnailURL
        }
        let audioParts = detail.childrenByKind
            .flatMap(\.entities)
            .filter { $0.kind == .audioTrack && !$0.isWanted }
            .sorted { lhs, rhs in
                (lhs.sortOrder ?? 0, lhs.title, lhs.id.uuidString)
                    < (rhs.sortOrder ?? 0, rhs.title, rhs.id.uuidString)
            }
        guard !audioParts.isEmpty else { return nil }

        bookID = detail.id
        title = detail.title
        tracks = audioParts.map {
            MusicTrack(
                thumbnail: $0,
                album: detail.title,
                artist: author,
                artworkPath: artwork
            )
        }
    }

    public var totalDuration: Double {
        Self.totalDuration(of: tracks)
    }

    public func resumePoint(at absoluteSeconds: Double) -> AudiobookResumePoint? {
        guard let first = tracks.first else { return nil }
        let duration = totalDuration
        guard duration > 0 else {
            return AudiobookResumePoint(trackID: first.id, trackOffsetSeconds: 0)
        }

        var remaining = min(max(0, absoluteSeconds), duration)
        for (index, track) in tracks.enumerated() {
            let trackDuration = Self.duration(of: track)
            if remaining < trackDuration || index == tracks.count - 1 {
                return AudiobookResumePoint(
                    trackID: track.id,
                    trackOffsetSeconds: min(max(0, remaining), trackDuration)
                )
            }
            remaining -= trackDuration
        }

        return AudiobookResumePoint(trackID: first.id, trackOffsetSeconds: 0)
    }

    public func absoluteTime(trackID: UUID, trackOffsetSeconds: Double) -> Double {
        Self.absoluteTime(
            in: tracks,
            trackID: trackID,
            trackOffsetSeconds: trackOffsetSeconds
        )
    }

    public static func totalDuration(of tracks: [MusicTrack]) -> Double {
        tracks.reduce(0) { $0 + duration(of: $1) }
    }

    public static func absoluteTime(
        in tracks: [MusicTrack],
        trackID: UUID,
        trackOffsetSeconds: Double
    ) -> Double {
        guard let index = tracks.firstIndex(where: { $0.id == trackID }) else { return 0 }
        let elapsedBefore = tracks.prefix(index).reduce(0) { $0 + duration(of: $1) }
        let trackDuration = duration(of: tracks[index])
        let localOffset = min(
            max(0, trackOffsetSeconds), trackDuration > 0 ? trackDuration : max(0, trackOffsetSeconds))
        return elapsedBefore + localOffset
    }

    private static func duration(of track: MusicTrack) -> Double {
        guard let duration = track.duration, duration.isFinite, duration > 0 else { return 0 }
        return duration
    }
}
