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
        return try await hydrate(thumbnails)
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
