import Foundation

public protocol PlaybackStatisticsLoading: Sendable {
    func loadStatistics(_ query: PlaybackStatisticsQuery) async throws -> PlaybackStatisticsResponse
    func loadThumbnails(ids: [UUID]) async throws -> [EntityThumbnail]
}
