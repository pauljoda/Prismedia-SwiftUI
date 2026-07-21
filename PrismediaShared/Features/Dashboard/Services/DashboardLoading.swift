import Foundation

public protocol DashboardLoading: Sendable {
    func load(_ query: EntityListQuery, limit: Int) async throws -> EntityListResponse
    func loadThumbnails(ids: [UUID]) async throws -> [EntityThumbnail]
}
