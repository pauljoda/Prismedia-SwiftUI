import Foundation

struct MusicLibraryQueueLoader: Sendable {
    private let client: PrismediaAPIClient

    init(client: PrismediaAPIClient) {
        self.client = client
    }

    func allTracks() async throws -> [MusicTrack] {
        try await tracks(
            matching: EntityListQuery(kind: .audioTrack, sort: PrismediaContractCodes.EntityListSort.title, sortDescending: false),
            search: nil
        )
    }

    func tracks(
        matching query: EntityListQuery,
        search: String?
    ) async throws -> [MusicTrack] {
        let thumbnails = try await client.listAllEntities(query, search: search)
        if query.kind == .audioLibrary {
            return try await tracks(in: thumbnails, artist: nil)
        }
        return thumbnails.filter { !$0.isWanted }.map { MusicTrack(thumbnail: $0) }
    }

    func shuffledTrackBatches(
        matching query: EntityListQuery,
        search: String?,
        pageSize: Int = 100,
        seed: Int = EntityGridControls.nextRandomSeed()
    ) -> AsyncThrowingStream<[MusicTrack], Error> {
        precondition(pageSize > 0, "A music queue page size must be positive.")
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    try await loadShuffledTrackBatches(
                        matching: query,
                        search: search,
                        pageSize: pageSize,
                        seed: seed,
                        continuation: continuation
                    )
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func hydrate(_ tracks: [EntityThumbnail]) async throws -> [MusicTrack] {
        let tracks = tracks.filter { !$0.isWanted }
        var albumsByID: [UUID: EntityThumbnail] = [:]
        var artistsByID: [UUID: EntityThumbnail] = [:]
        return try await hydrate(
            tracks,
            albumsByID: &albumsByID,
            artistsByID: &artistsByID
        )
    }

    func tracks(in albums: [EntityThumbnail], artist: String?) async throws -> [MusicTrack] {
        let childGroups = try await client.fetchEntityChildren(parentIDs: albums.map(\.id))
        let childrenByAlbum = Dictionary(uniqueKeysWithValues: childGroups.map { ($0.parentId, $0.items) })
        let artistIDs = artist == nil ? unique(albums.compactMap(\.parentEntityID)) : []
        let artistsByID = Dictionary(uniqueKeysWithValues: try await thumbnails(ids: artistIDs).map { ($0.id, $0) })

        return albums.flatMap { album in
            MusicEntityProjection.tracks(
                in: album,
                children: childrenByAlbum[album.id] ?? [],
                artist: artist ?? album.parentEntityID.flatMap { artistsByID[$0]?.title }
            )
        }
    }

    private func loadShuffledTrackBatches(
        matching query: EntityListQuery,
        search: String?,
        pageSize: Int,
        seed: Int,
        continuation: AsyncThrowingStream<[MusicTrack], Error>.Continuation
    ) async throws {
        var query = query
        query.sort = EntityGridSort.random.rawValue
        query.sortDescending = false
        query.seed = seed
        query.cursor = nil
        var cursor: String?
        var visitedCursors = Set<String>()
        var seenTrackIDs = Set<UUID>()
        var albumsByID: [UUID: EntityThumbnail] = [:]
        var artistsByID: [UUID: EntityThumbnail] = [:]

        while true {
            try Task.checkCancellation()
            query.cursor = cursor
            let response = try await client.listEntities(query, limit: pageSize, search: search)
            if query.kind == .audioLibrary {
                try await yieldAlbumTrackBatches(
                    response.items,
                    artistsByID: &artistsByID,
                    seenTrackIDs: &seenTrackIDs,
                    continuation: continuation
                )
            } else {
                let hydratedTracks = try await hydrate(
                    response.items,
                    albumsByID: &albumsByID,
                    artistsByID: &artistsByID
                )
                let tracks = uniqueTracks(
                    hydratedTracks,
                    seenTrackIDs: &seenTrackIDs
                )
                if !tracks.isEmpty { continuation.yield(tracks) }
            }

            guard let nextCursor = response.nextCursor,
                visitedCursors.insert(nextCursor).inserted
            else { return }
            cursor = nextCursor
        }
    }

    private func yieldAlbumTrackBatches(
        _ albums: [EntityThumbnail],
        artistsByID: inout [UUID: EntityThumbnail],
        seenTrackIDs: inout Set<UUID>,
        continuation: AsyncThrowingStream<[MusicTrack], Error>.Continuation
    ) async throws {
        let unresolvedArtistIDs = unique(albums.compactMap(\.parentEntityID))
            .filter { artistsByID[$0] == nil }
        let artists = try await thumbnails(ids: unresolvedArtistIDs)
        for artist in artists { artistsByID[artist.id] = artist }

        let childGroups = try await client.fetchEntityChildren(parentIDs: albums.map(\.id))
        let childrenByAlbum = Dictionary(uniqueKeysWithValues: childGroups.map { ($0.parentId, $0.items) })
        for album in albums {
            let artist =
                album.parentEntityID.flatMap { artistsByID[$0]?.title }
                ?? album.musicMetadataValue(matching: ["artist", "person"])
            let albumTracks = MusicEntityProjection.tracks(
                in: album,
                children: childrenByAlbum[album.id] ?? [],
                artist: artist
            )
            let tracks = uniqueTracks(albumTracks, seenTrackIDs: &seenTrackIDs)
            if !tracks.isEmpty { continuation.yield(tracks) }
        }
    }

    private func hydrate(
        _ tracks: [EntityThumbnail],
        albumsByID: inout [UUID: EntityThumbnail],
        artistsByID: inout [UUID: EntityThumbnail]
    ) async throws -> [MusicTrack] {
        let albumIDs = unique(tracks.compactMap(\.parentEntityID))
        let unresolvedAlbumIDs =
            albumIDs
            .filter { albumsByID[$0] == nil }
        let albums = try await thumbnails(ids: unresolvedAlbumIDs)
        for album in albums { albumsByID[album.id] = album }

        let artistIDs = unique(albumIDs.compactMap { albumsByID[$0]?.parentEntityID })
        let unresolvedArtistIDs =
            artistIDs
            .filter { artistsByID[$0] == nil }
        let artists = try await thumbnails(ids: unresolvedArtistIDs)
        for artist in artists { artistsByID[artist.id] = artist }

        return MusicEntityProjection.libraryTracks(
            tracks,
            albumsByID: albumsByID,
            artistsByID: artistsByID
        )
    }

    private func uniqueTracks(
        _ tracks: [MusicTrack],
        seenTrackIDs: inout Set<UUID>
    ) -> [MusicTrack] {
        tracks.filter { seenTrackIDs.insert($0.id).inserted }
    }

    private func thumbnails(ids: [UUID]) async throws -> [EntityThumbnail] {
        var items: [EntityThumbnail] = []
        for start in stride(from: 0, to: ids.count, by: 250) {
            try Task.checkCancellation()
            let end = min(start + 250, ids.count)
            items += try await client.fetchEntityThumbnails(ids: Array(ids[start..<end]))
        }
        return items
    }

    private func unique(_ ids: [UUID]) -> [UUID] {
        var seen = Set<UUID>()
        return ids.filter { seen.insert($0).inserted }
    }
}
