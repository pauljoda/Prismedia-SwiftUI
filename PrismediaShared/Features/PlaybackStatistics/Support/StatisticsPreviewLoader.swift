import SwiftUI

#if DEBUG
    struct StatisticsPreviewLoader: PlaybackStatisticsLoading {
        func loadStatistics(_ query: PlaybackStatisticsQuery) async throws -> PlaybackStatisticsResponse {
            let item = PrismediaPreviewData.allEntities[0]
            let eventDate = Date(timeIntervalSince1970: 1_752_201_600)
            return PlaybackStatisticsResponse(
                from: query.from,
                to: query.to,
                totalEvents: 18,
                completedCount: 15,
                skippedCount: 3,
                distinctEntityCount: 1,
                topEntities: [
                    PlaybackStatisticsEntity(
                        id: item.id,
                        kind: item.kind,
                        title: item.title,
                        coverURL: item.bestCoverPath,
                        completedCount: 15,
                        skippedCount: 3,
                        lastEventAt: eventDate
                    )
                ],
                recentEvents: [
                    PlaybackStatisticsEvent(
                        id: UUID(uuidString: "3B3684F3-0A12-4E05-AD5C-EFB79652F997")!,
                        entityID: item.id,
                        entityKind: item.kind,
                        entityTitle: item.title,
                        coverURL: item.bestCoverPath,
                        kind: .completed,
                        occurredAt: eventDate,
                        positionSeconds: nil,
                        durationSeconds: nil
                    )
                ],
                dailyEvents: [
                    PlaybackStatisticsBucket(
                        date: "2026-07-11",
                        completedCount: 15,
                        skippedCount: 3
                    )
                ]
            )
        }

        func loadThumbnails(ids: [UUID]) async throws -> [EntityThumbnail] {
            PrismediaPreviewData.allEntities.filter { ids.contains($0.id) }
        }
    }

#endif
