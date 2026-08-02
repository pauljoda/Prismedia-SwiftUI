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
                accessedCount: 12,
                completedCount: 15,
                skippedCount: 3,
                distinctEntityCount: 1,
                activeSeconds: 42_300,
                viewingSeconds: 24_300,
                readingSeconds: 7_200,
                listeningSeconds: 10_800,
                topEntities: [
                    PlaybackStatisticsEntity(
                        id: item.id,
                        kind: item.kind,
                        title: item.title,
                        coverURL: item.bestCoverPath,
                        accessedCount: 12,
                        completedCount: 15,
                        skippedCount: 3,
                        activeSeconds: 42_300,
                        firstEventAt: eventDate.addingTimeInterval(-86_400),
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
                        accessedCount: 12,
                        completedCount: 15,
                        skippedCount: 3,
                        activeSeconds: 42_300,
                        viewingSeconds: 24_300,
                        listeningSeconds: 10_800,
                        readingSeconds: 7_200
                    )
                ],
                kindBreakdown: [
                    PlaybackStatisticsKindSlice(
                        kind: item.kind,
                        totalEvents: 18,
                        accessedCount: 12,
                        completedCount: 15,
                        skippedCount: 3,
                        distinctEntityCount: 1,
                        activeSeconds: 42_300
                    )
                ],
                rhythm: [
                    PlaybackStatisticsRhythmCell(
                        dayOfWeek: 6,
                        hour: 20,
                        accessedCount: 7,
                        completedCount: 4,
                        skippedCount: 1
                    )
                ]
            )
        }

        func loadThumbnails(ids: [UUID]) async throws -> [EntityThumbnail] {
            PrismediaPreviewData.allEntities.filter { ids.contains($0.id) }
        }
    }

#endif
