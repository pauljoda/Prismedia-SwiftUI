import Foundation

public protocol SearchHubLoading: Sendable {
    var allowsNsfwContent: Bool { get }

    func loadRecent(limit: Int) async throws -> EntityListResponse
    func search(
        query: String,
        filters: SearchHubFilterState,
        limit: Int,
        cursor: String?
    ) async throws -> EntityListResponse
}

extension SearchHubLoading {
    func search(query: String, limit: Int, cursor: String?) async throws -> EntityListResponse {
        try await search(
            query: query,
            filters: SearchHubFilterState(),
            limit: limit,
            cursor: cursor
        )
    }
}
