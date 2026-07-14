import Foundation

public protocol EntityGridLoading: Sendable {
    var allowsNsfwContent: Bool { get }

    func load(
        query: EntityListQuery,
        limit: Int,
        search: String?,
        cursor: String?
    ) async throws -> EntityListResponse
}
