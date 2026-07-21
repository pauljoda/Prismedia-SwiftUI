import Foundation

public struct PrismediaDashboardLoader: DashboardLoading, Sendable {
    private let client: PrismediaAPIClient

    public init(client: PrismediaAPIClient) {
        self.client = client
    }

    public func load(_ query: EntityListQuery, limit: Int) async throws -> EntityListResponse {
        try await client.listEntities(query, limit: limit)
    }

    public func loadThumbnails(ids: [UUID]) async throws -> [EntityThumbnail] {
        try await client.fetchEntityThumbnails(ids: ids)
    }
}
