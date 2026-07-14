import SwiftUI

public struct PrismediaTVHomeLoader: TVHomeLoading, Sendable {
    private let client: PrismediaAPIClient

    public init(client: PrismediaAPIClient) {
        self.client = client
    }

    public func load(shelf: TVHomeShelf) async throws -> [EntityThumbnail] {
        do {
            return try await client.listEntities(shelf.query, limit: shelf.limit).items
                .filter(shelf.accepts)
        } catch PrismediaAPIError.httpStatus(400, _) where !shelf.query.kinds.isEmpty {
            // Servers predating multi-kind filtering remain usable during the
            // backend rollout. Preserve shelf ordering and filter locally.
            var legacyQuery = shelf.query
            legacyQuery.kinds = []
            return try await client.listEntities(
                legacyQuery,
                limit: max(shelf.limit, 200)
            ).items.filter(shelf.accepts).prefix(shelf.limit).map { $0 }
        }
    }
}
