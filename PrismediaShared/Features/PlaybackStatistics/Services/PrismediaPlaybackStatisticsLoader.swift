import Foundation

public struct PrismediaPlaybackStatisticsLoader: PlaybackStatisticsLoading, Sendable {
    private let client: PrismediaAPIClient

    public init(client: PrismediaAPIClient) {
        self.client = client
    }

    public func loadStatistics(
        _ query: PlaybackStatisticsQuery
    ) async throws -> PlaybackStatisticsResponse {
        try await client.fetchPlaybackStatistics(query)
    }

    public func loadThumbnails(ids: [UUID]) async throws -> [EntityThumbnail] {
        try await client.fetchEntityThumbnails(ids: ids)
    }
}
