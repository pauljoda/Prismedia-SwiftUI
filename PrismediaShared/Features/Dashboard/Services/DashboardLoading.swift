import Foundation

public protocol DashboardLoading: Sendable {
    func load(_ query: EntityListQuery, limit: Int) async throws -> EntityListResponse
}
