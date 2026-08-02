import Foundation

public struct PrismediaConsumptionStatisticsLoader: ConsumptionStatisticsLoading, Sendable {
    private let client: PrismediaAPIClient

    public init(client: PrismediaAPIClient) {
        self.client = client
    }

    public func loadStatistics(
        _ query: ConsumptionStatisticsQuery
    ) async throws -> ConsumptionStatisticsResponse {
        try await client.fetchConsumptionStatistics(query)
    }

    public func loadThumbnails(ids: [UUID]) async throws -> [EntityThumbnail] {
        try await client.fetchEntityThumbnails(ids: ids)
    }
}
