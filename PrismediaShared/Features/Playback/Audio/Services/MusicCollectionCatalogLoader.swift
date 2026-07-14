import Foundation

struct MusicCollectionCatalogLoader: EntityGridLoading, Sendable {
    let allowsNsfwContent: Bool

    private let catalogLoader: any EntityGridLoading
    private let collectionItemsLoader: any CollectionItemsLoading
    private let membershipConcurrency: Int

    init(
        catalogLoader: any EntityGridLoading,
        collectionItemsLoader: any CollectionItemsLoading,
        membershipConcurrency: Int = 6
    ) {
        precondition(membershipConcurrency > 0, "Collection membership concurrency must be positive.")
        self.catalogLoader = catalogLoader
        self.collectionItemsLoader = collectionItemsLoader
        self.membershipConcurrency = membershipConcurrency
        allowsNsfwContent = catalogLoader.allowsNsfwContent
    }

    func load(
        query: EntityListQuery,
        limit: Int,
        search: String?,
        cursor: String?
    ) async throws -> EntityListResponse {
        guard cursor == nil else { return EntityListResponse(items: [], totalCount: 0) }
        let collections = try await allCollections(query: query, limit: limit, search: search)
        let audioCollections = try await filterAudioCollections(collections)
        return EntityListResponse(items: audioCollections, totalCount: audioCollections.count)
    }

    private func allCollections(
        query: EntityListQuery,
        limit: Int,
        search: String?
    ) async throws -> [EntityThumbnail] {
        var items: [EntityThumbnail] = []
        var seen = Set<UUID>()
        var visitedCursors = Set<String>()
        var nextCursor: String?

        repeat {
            try Task.checkCancellation()
            var pageQuery = query
            pageQuery.cursor = nextCursor
            let response = try await catalogLoader.load(
                query: pageQuery,
                limit: max(limit, 250),
                search: search,
                cursor: nextCursor
            )
            items += response.items.filter { seen.insert($0.id).inserted }
            guard let cursor = response.nextCursor, visitedCursors.insert(cursor).inserted else {
                nextCursor = nil
                continue
            }
            nextCursor = cursor
        } while nextCursor != nil

        return items
    }

    private func filterAudioCollections(
        _ collections: [EntityThumbnail]
    ) async throws -> [EntityThumbnail] {
        var matches = Array(repeating: false, count: collections.count)

        for batchStart in stride(from: 0, to: collections.count, by: membershipConcurrency) {
            let batchEnd = min(batchStart + membershipConcurrency, collections.count)
            let resolved = try await withThrowingTaskGroup(
                of: (Int, Bool).self,
                returning: [(Int, Bool)].self
            ) { group in
                for index in batchStart..<batchEnd {
                    let collection = collections[index]
                    group.addTask {
                        let members = try await collectionItemsLoader.loadCollectionItems(
                            collectionID: collection.id
                        )
                        return (index, members.contains(where: Self.isAudioMember))
                    }
                }

                var values: [(Int, Bool)] = []
                for try await value in group { values.append(value) }
                return values
            }
            for (index, isAudio) in resolved { matches[index] = isAudio }
        }

        return collections.enumerated().compactMap { index, collection in
            matches[index] ? collection : nil
        }
    }

    private static func isAudioMember(_ member: EntityThumbnail) -> Bool {
        member.kind == .audioTrack || member.kind == .audioLibrary || member.kind == .musicArtist
    }
}
