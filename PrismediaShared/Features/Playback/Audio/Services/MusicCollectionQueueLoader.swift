import Foundation

struct MusicCollectionQueueLoader: Sendable {
    private let collectionItemsLoader: any CollectionItemsLoading
    private let detailLoader: any EntityDetailLoading

    init(
        collectionItemsLoader: any CollectionItemsLoading,
        detailLoader: any EntityDetailLoading
    ) {
        self.collectionItemsLoader = collectionItemsLoader
        self.detailLoader = detailLoader
    }

    func load(collectionID: UUID) async throws -> MusicCollectionPlaybackSnapshot {
        let members = try await collectionItemsLoader.loadCollectionItems(collectionID: collectionID)
        var sections: [MusicTrackSection] = []
        var detailsByID: [UUID: EntityDetail] = [:]

        for member in members {
            try Task.checkCancellation()
            var visited = Set<UUID>()
            let tracks = try await tracks(
                for: member,
                visited: &visited,
                detailsByID: &detailsByID
            )
            sections += sourceSections(for: member, tracks: tracks)
        }

        return MusicCollectionPlaybackSnapshot(sections: sections)
    }

    private func tracks(
        for member: EntityThumbnail,
        visited: inout Set<UUID>,
        detailsByID: inout [UUID: EntityDetail]
    ) async throws -> [MusicTrack] {
        switch member.kind {
        case .audioTrack, .audio:
            guard !member.isWanted else { return [] }
            return [try await hydratedTrack(member, detailsByID: &detailsByID)]
        case .audioLibrary:
            return try await libraryTracks(
                id: member.id,
                artist: nil,
                visited: &visited,
                detailsByID: &detailsByID
            )
        case .musicArtist:
            return try await artistTracks(
                id: member.id,
                visited: &visited,
                detailsByID: &detailsByID
            )
        default:
            return []
        }
    }

    private func libraryTracks(
        id: UUID,
        artist: String?,
        visited: inout Set<UUID>,
        detailsByID: inout [UUID: EntityDetail]
    ) async throws -> [MusicTrack] {
        guard visited.insert(id).inserted else { return [] }
        let detail = try await detail(id: id, detailsByID: &detailsByID)
        let resolvedArtist: String?
        if let artist {
            resolvedArtist = artist
        } else {
            resolvedArtist = try await artistName(for: detail, detailsByID: &detailsByID)
        }
        var tracks = MusicEntityProjection.tracks(in: detail, artist: resolvedArtist)

        for library in orderedEntities(of: .audioLibrary, in: detail) {
            try Task.checkCancellation()
            tracks += try await libraryTracks(
                id: library.id,
                artist: resolvedArtist,
                visited: &visited,
                detailsByID: &detailsByID
            )
        }
        return tracks
    }

    private func artistTracks(
        id: UUID,
        visited: inout Set<UUID>,
        detailsByID: inout [UUID: EntityDetail]
    ) async throws -> [MusicTrack] {
        guard visited.insert(id).inserted else { return [] }
        let detail = try await detail(id: id, detailsByID: &detailsByID)
        var tracks = MusicEntityProjection.tracks(in: detail, artist: detail.title)

        for album in orderedEntities(of: .audioLibrary, in: detail) {
            try Task.checkCancellation()
            tracks += try await libraryTracks(
                id: album.id,
                artist: detail.title,
                visited: &visited,
                detailsByID: &detailsByID
            )
        }
        return tracks
    }

    private func hydratedTrack(
        _ thumbnail: EntityThumbnail,
        detailsByID: inout [UUID: EntityDetail]
    ) async throws -> MusicTrack {
        let track = MusicTrack(thumbnail: thumbnail)
        guard let parentID = thumbnail.parentEntityID,
            let album = try await optionalDetail(id: parentID, detailsByID: &detailsByID),
            album.kind == .audioLibrary
        else { return track }

        let artist: String?
        if let trackArtist = track.artist {
            artist = trackArtist
        } else {
            artist = try await artistName(for: album, detailsByID: &detailsByID)
        }
        return MusicEntityProjection.tracks(in: album, artist: artist)
            .first { $0.id == thumbnail.id }
            ?? MusicTrack(
                thumbnail: thumbnail,
                album: track.album ?? album.title,
                artist: artist
            )
    }

    private func artistName(
        for detail: EntityDetail,
        detailsByID: inout [UUID: EntityDetail]
    ) async throws -> String? {
        var visited = Set<UUID>()
        return try await artistName(
            for: detail,
            visited: &visited,
            detailsByID: &detailsByID
        )
    }

    private func artistName(
        for detail: EntityDetail,
        visited: inout Set<UUID>,
        detailsByID: inout [UUID: EntityDetail]
    ) async throws -> String? {
        if let relatedArtist = detail.relationships
            .first(where: { $0.kind == .musicArtist || $0.kind == .person })?
            .entities.first?.title
        {
            return relatedArtist
        }

        guard visited.insert(detail.id).inserted,
            let parentID = detail.parentEntityID,
            let parent = try await optionalDetail(id: parentID, detailsByID: &detailsByID)
        else { return nil }

        if parent.kind == .musicArtist || parent.kind == .person {
            return parent.title
        }
        guard parent.kind == .audioLibrary else { return nil }
        return try await artistName(
            for: parent,
            visited: &visited,
            detailsByID: &detailsByID
        )
    }

    private func detail(
        id: UUID,
        detailsByID: inout [UUID: EntityDetail]
    ) async throws -> EntityDetail {
        if let detail = detailsByID[id] { return detail }
        let detail = try await detailLoader.loadEntity(id: id)
        detailsByID[id] = detail
        return detail
    }

    private func optionalDetail(
        id: UUID,
        detailsByID: inout [UUID: EntityDetail]
    ) async throws -> EntityDetail? {
        do {
            return try await detail(id: id, detailsByID: &detailsByID)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            return nil
        }
    }

    private func orderedEntities(
        of kind: EntityKind,
        in detail: EntityDetail
    ) -> [EntityThumbnail] {
        (detail.childrenByKind + detail.relationships)
            .filter { $0.kind == kind }
            .flatMap(\.entities)
            .enumerated()
            .sorted { lhs, rhs in
                let left = lhs.element.sortOrder ?? Int.max
                let right = rhs.element.sortOrder ?? Int.max
                return left == right ? lhs.offset < rhs.offset : left < right
            }
            .map(\.element)
    }

    private func sourceSections(
        for member: EntityThumbnail,
        tracks: [MusicTrack]
    ) -> [MusicTrackSection] {
        guard !tracks.isEmpty else { return [] }
        let discSections = MusicTrackSection.sections(for: tracks)
        return discSections.map { section in
            let title = section.title.map { "\(member.title) · \($0)" } ?? member.title
            return MusicTrackSection(title: title, tracks: section.tracks)
        }
    }
}
