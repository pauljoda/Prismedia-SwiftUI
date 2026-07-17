import Foundation

struct MusicLibraryQueueLoader: Sendable {
    private let client: PrismediaAPIClient

    init(client: PrismediaAPIClient) {
        self.client = client
    }

    func allTracks() async throws -> [MusicTrack] {
        try await tracks(
            matching: EntityListQuery(kind: .audioTrack, sort: "title", sortDescending: false),
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
        return thumbnails.map { MusicTrack(thumbnail: $0) }
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
        let albumIDs = unique(tracks.compactMap(\.parentEntityID))
        let albums = try await thumbnails(ids: albumIDs)
        let albumsByID = Dictionary(uniqueKeysWithValues: albums.map { ($0.id, $0) })
        let artistIDs = unique(albums.compactMap(\.parentEntityID))
        let artists = try await thumbnails(ids: artistIDs)
        let artistsByID = Dictionary(uniqueKeysWithValues: artists.map { ($0.id, $0) })
        return MusicEntityProjection.libraryTracks(
            tracks,
            albumsByID: albumsByID,
            artistsByID: artistsByID
        )
    }

    func tracks(in albums: [EntityThumbnail], artist: String?) async throws -> [MusicTrack] {
        var indexedTracks: [(Int, [MusicTrack])] = []
        for batchStart in stride(from: 0, to: albums.count, by: 6) {
            let batchEnd = min(batchStart + 6, albums.count)
            let batch = try await withThrowingTaskGroup(
                of: (Int, [MusicTrack]).self,
                returning: [(Int, [MusicTrack])].self
            ) { group in
                for index in batchStart..<batchEnd {
                    let album = albums[index]
                    group.addTask {
                        let detail = try await client.fetchEntity(id: album.id)
                        return (index, MusicEntityProjection.tracks(in: detail, artist: artist))
                    }
                }

                var results: [(Int, [MusicTrack])] = []
                for try await result in group { results.append(result) }
                return results
            }
            indexedTracks += batch
        }
        return indexedTracks.sorted { $0.0 < $1.0 }.flatMap(\.1)
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

        while true {
            try Task.checkCancellation()
            query.cursor = cursor
            let response = try await client.listEntities(query, limit: pageSize, search: search)
            if query.kind == .audioLibrary {
                try await yieldAlbumTrackBatches(
                    response.items,
                    seenTrackIDs: &seenTrackIDs,
                    continuation: continuation
                )
            } else {
                let tracks = uniqueTracks(
                    response.items.map { MusicTrack(thumbnail: $0) },
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
        seenTrackIDs: inout Set<UUID>,
        continuation: AsyncThrowingStream<[MusicTrack], Error>.Continuation
    ) async throws {
        for batchStart in stride(from: 0, to: albums.count, by: 6) {
            let batchEnd = min(batchStart + 6, albums.count)
            try await withThrowingTaskGroup(of: [MusicTrack].self) { group in
                for album in albums[batchStart..<batchEnd] {
                    group.addTask {
                        let detail = try await client.fetchEntity(id: album.id)
                        return MusicEntityProjection.tracks(in: detail, artist: nil)
                    }
                }
                for try await albumTracks in group {
                    let tracks = uniqueTracks(albumTracks, seenTrackIDs: &seenTrackIDs)
                    if !tracks.isEmpty { continuation.yield(tracks) }
                }
            }
        }
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
