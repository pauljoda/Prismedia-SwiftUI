import Foundation

/// Stateless consumption-statistics use case. The SwiftUI view owns the returned
/// value snapshot and decides when a newer query replaces it.
@MainActor
public struct ConsumptionStatisticsService {
    private let loader: any ConsumptionStatisticsLoading

    public init(loader: any ConsumptionStatisticsLoading) {
        self.loader = loader
    }

    public func load(
        _ query: ConsumptionStatisticsQuery
    ) async -> ConsumptionStatisticsSnapshot {
        do {
            let response = try await loader.loadStatistics(query)
            let ids = Array(
                Set(
                    response.topEntities.map(\.id)
                        + response.recentEvents.map(\.entityID)
                ))
            let thumbnails = try await loader.loadThumbnails(ids: ids)
            guard !Task.isCancelled else {
                return ConsumptionStatisticsSnapshot(state: .idle)
            }

            return ConsumptionStatisticsSnapshot(
                response: response,
                thumbnailsByID: Dictionary(
                    uniqueKeysWithValues: thumbnails.map { ($0.id, $0) }
                ),
                state: response.totalEvents == 0 && response.activeSeconds <= 0 ? .empty : .content
            )
        } catch is CancellationError {
            return ConsumptionStatisticsSnapshot(state: .idle)
        } catch {
            return ConsumptionStatisticsSnapshot(
                state: .failed("Consumption history couldn’t be loaded.")
            )
        }
    }
}
