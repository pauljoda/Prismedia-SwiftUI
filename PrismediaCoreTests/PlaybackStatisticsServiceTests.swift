import XCTest

@testable import PrismediaCore

final class PlaybackStatisticsServiceTests: XCTestCase {
    @MainActor
    func testLoadReturnsAContentSnapshotWithResolvedThumbnails() async {
        let entity = EntityThumbnail(
            id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!,
            kind: .movie,
            title: "Arrival"
        )
        let loader = PlaybackStatisticsLoaderStub(
            response: response(totalEvents: 1, entityID: entity.id),
            thumbnails: [entity]
        )
        let service = PlaybackStatisticsService(loader: loader)

        let snapshot = await service.load(query)

        XCTAssertEqual(snapshot.state, .content)
        XCTAssertEqual(snapshot.response?.totalEvents, 1)
        XCTAssertEqual(snapshot.thumbnailsByID[entity.id], entity)
    }

    @MainActor
    func testLoadReturnsAnEmptySnapshotWhenThereAreNoEvents() async {
        let loader = PlaybackStatisticsLoaderStub(
            response: response(totalEvents: 0),
            thumbnails: []
        )
        let service = PlaybackStatisticsService(loader: loader)

        let snapshot = await service.load(query)

        XCTAssertEqual(snapshot.state, .empty)
        XCTAssertEqual(snapshot.response?.totalEvents, 0)
    }

    private var query: PlaybackStatisticsQuery {
        PlaybackStatisticsQuery(
            from: Date(timeIntervalSince1970: 0),
            to: Date(timeIntervalSince1970: 100)
        )
    }

    private func response(
        totalEvents: Int,
        entityID: UUID? = nil
    ) -> PlaybackStatisticsResponse {
        let topEntities =
            entityID.map {
                [
                    PlaybackStatisticsEntity(
                        id: $0,
                        kind: .movie,
                        title: "Arrival",
                        coverURL: nil,
                        completedCount: totalEvents,
                        skippedCount: 0,
                        lastEventAt: Date(timeIntervalSince1970: 100)
                    )
                ]
            } ?? []

        return PlaybackStatisticsResponse(
            from: query.from,
            to: query.to,
            totalEvents: totalEvents,
            completedCount: totalEvents,
            skippedCount: 0,
            distinctEntityCount: entityID == nil ? 0 : 1,
            topEntities: topEntities,
            recentEvents: [],
            dailyEvents: []
        )
    }
}

private struct PlaybackStatisticsLoaderStub: PlaybackStatisticsLoading {
    let response: PlaybackStatisticsResponse
    let thumbnails: [EntityThumbnail]

    func loadStatistics(
        _ query: PlaybackStatisticsQuery
    ) async throws -> PlaybackStatisticsResponse {
        response
    }

    func loadThumbnails(ids: [UUID]) async throws -> [EntityThumbnail] {
        thumbnails.filter { ids.contains($0.id) }
    }
}
