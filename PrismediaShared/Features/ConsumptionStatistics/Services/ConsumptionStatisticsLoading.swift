import Foundation

public protocol ConsumptionStatisticsLoading: Sendable {
    func loadStatistics(_ query: ConsumptionStatisticsQuery) async throws -> ConsumptionStatisticsResponse
    func loadThumbnails(ids: [UUID]) async throws -> [EntityThumbnail]
}
