import Foundation

/// Stateless playback-statistics use case. The SwiftUI view owns the returned
/// value snapshot and decides when a newer query replaces it.
@MainActor
public struct PlaybackStatisticsService {
    private let loader: any PlaybackStatisticsLoading

    public init(loader: any PlaybackStatisticsLoading) {
        self.loader = loader
    }

    public func load(
        _ query: PlaybackStatisticsQuery
    ) async -> PlaybackStatisticsSnapshot {
        do {
            let response = try await loader.loadStatistics(query)
            let ids = Array(
                Set(
                    response.topEntities.map(\.id)
                        + response.recentEvents.map(\.entityID)
                ))
            let thumbnails = try await loader.loadThumbnails(ids: ids)
            guard !Task.isCancelled else {
                return PlaybackStatisticsSnapshot(state: .idle)
            }

            return PlaybackStatisticsSnapshot(
                response: response,
                thumbnailsByID: Dictionary(
                    uniqueKeysWithValues: thumbnails.map { ($0.id, $0) }
                ),
                state: response.totalEvents == 0 ? .empty : .content
            )
        } catch is CancellationError {
            return PlaybackStatisticsSnapshot(state: .idle)
        } catch {
            return PlaybackStatisticsSnapshot(
                state: .failed("Playback history couldn’t be loaded.")
            )
        }
    }
}
