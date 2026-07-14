import Foundation

public protocol SearchHubLoading: Sendable {
    var allowsNsfwContent: Bool { get }

    func loadRecent(limit: Int) async throws -> EntityListResponse
    func search(query: String, limit: Int, cursor: String?) async throws -> EntityListResponse
}
