import Foundation

public struct PrismediaSearchHubLoader: SearchHubLoading, Sendable {
    private let client: PrismediaAPIClient

    public init(client: PrismediaAPIClient) {
        self.client = client
    }

    public var allowsNsfwContent: Bool { client.allowsNsfwContent }

    public func loadRecent(limit: Int) async throws -> EntityListResponse {
        let itemLimit = max(1, limit / SearchHubCatalog.previewKinds.count)
        let indexedItems = try await withThrowingTaskGroup(
            of: (Int, [EntityThumbnail]).self,
            returning: [(Int, [EntityThumbnail])].self
        ) { group in
            for (index, kind) in SearchHubCatalog.previewKinds.enumerated() {
                group.addTask { [client] in
                    let response = try await client.listEntities(
                        EntityListQuery(kind: kind, sort: "added", sortDescending: true),
                        limit: itemLimit
                    )
                    return (index, response.items)
                }
            }

            var results: [(Int, [EntityThumbnail])] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }
        let items =
            indexedItems
            .sorted { $0.0 < $1.0 }
            .flatMap(\.1)
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
