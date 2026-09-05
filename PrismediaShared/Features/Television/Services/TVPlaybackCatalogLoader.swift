import Foundation

/// Keeps TV lists playback-only without changing shared-client or server catalog semantics.
struct TVPlaybackCatalogLoader: EntityGridLoading {
    let client: PrismediaAPIClient
    var allowsNsfwContent: Bool { client.allowsNsfwContent }

    func load(query: EntityListQuery, limit: Int, search: String?, cursor: String?) async throws -> EntityListResponse {
        var query = query
        let kinds = query.kind.map { [$0] } ?? query.kinds
        if !kinds.contains(.collection) {
            query.hasFile = true
            query.cursor = cursor
            return try await client.listEntities(query, limit: limit, search: search)
        }

        // Collections own relationships, not source files. Resolve membership before
        // local paging so hidden collections cannot produce empty pages or false counts.
        query.hasFile = nil
        query.cursor = nil
        var visible: [EntityThumbnail] = []
        repeat {
            let page = try await client.listEntities(query, limit: 200, search: search)
            for item in page.items {
                if item.kind == .collection {
                    let members = try await client.fetchCollectionItems(collectionID: item.id)
                    if members.contains(where: TVPlaybackCatalogPolicy.accepts) { visible.append(item) }
                } else if TVPlaybackCatalogPolicy.accepts(item) {
                    visible.append(item)
                }
            }
            query.cursor = page.nextCursor
        } while query.cursor != nil

        let offset = cursor.flatMap(Int.init) ?? 0
        let page = Array(visible.dropFirst(offset).prefix(limit))
        let nextOffset = offset + page.count
        return EntityListResponse(
            items: page, nextCursor: nextOffset < visible.count ? String(nextOffset) : nil,
            totalCount: visible.count)
    }
}
