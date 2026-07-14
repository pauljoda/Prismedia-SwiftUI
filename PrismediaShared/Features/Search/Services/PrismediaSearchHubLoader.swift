import Foundation

public struct PrismediaSearchHubLoader: SearchHubLoading, Sendable {
    private let client: PrismediaAPIClient

    public init(client: PrismediaAPIClient) {
        self.client = client
    }

    public var allowsNsfwContent: Bool { client.allowsNsfwContent }

    public func loadRecent(limit: Int) async throws -> EntityListResponse {
        let itemLimit = max(1, limit / SearchHubCatalog.previewKinds.count)
        var items: [EntityThumbnail] = []
        for kind in SearchHubCatalog.previewKinds {
            let response = try await client.listEntities(
                EntityListQuery(kind: kind, sort: "added", sortDescending: true),
                limit: itemLimit
            )
            items += response.items
        }
        return EntityListResponse(items: items, totalCount: items.count)
    }

    public func search(query: String, limit: Int, cursor: String?) async throws -> EntityListResponse {
        try await client.listEntities(
            EntityListQuery(cursor: cursor),
            limit: limit,
            search: query
        )
    }
}
