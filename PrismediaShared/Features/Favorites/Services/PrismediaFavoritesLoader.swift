import Foundation

public struct PrismediaFavoritesLoader: FavoritesLoading, Sendable {
    private let client: PrismediaAPIClient

    public init(client: PrismediaAPIClient) {
        self.client = client
    }

    public func load(_ query: EntityListQuery, limit: Int) async throws -> EntityListResponse {
        try await client.listEntities(query, limit: limit)
    }
}
