import Foundation

public struct PrismediaEntityGridLoader: EntityGridLoading, Sendable {
    private let client: PrismediaAPIClient

    public init(client: PrismediaAPIClient) {
        self.client = client
    }

    public var allowsNsfwContent: Bool { client.allowsNsfwContent }

    public func load(
        query: EntityListQuery,
        limit: Int,
        search: String?,
        cursor: String?
    ) async throws -> EntityListResponse {
        var pageQuery = query
        pageQuery.cursor = cursor
        return try await client.listEntities(
            pageQuery,
            limit: limit,
            search: search
        )
    }
}
