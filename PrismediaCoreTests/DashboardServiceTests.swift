import XCTest

@testable import PrismediaCore

final class DashboardServiceTests: XCTestCase {
    func testEveryDashboardShelfTargetsItsCanonicalLibraryDestination() {
        let expected = [
            "video": "videos", "movie": "movies", "video-series": "series",
            "gallery": "galleries", "book": "books", "image": "images",
            "audio-library": "albums", "collection": "collections",
            "person": "people", "studio": "studios", "tag": "tags",
        ]

        XCTAssertEqual(
            Dictionary(uniqueKeysWithValues: DashboardCatalog.sections.map { ($0.kind.rawValue, $0.destinationID) }),
            expected
        )

        for section in DashboardCatalog.sections {
            let mode = ModeCatalog.mode(containing: section.destinationID)
            XCTAssertNotNil(mode?.destination(id: section.destinationID)?.entityList)
        }
        XCTAssertEqual(ModeCatalog.mode(containing: "collections")?.id, "browse")
    }

    @MainActor
    func testLoadBuildsHeroContinueRecentAndCollectionShelf() async {
        let first = item(1, kind: .movie, title: "Arrival")
        let second = item(2, kind: .video, title: "Pilot")
        let watched = item(3, kind: .audioTrack, title: "Signals")
        let collection = item(4, kind: .collection, title: "Favorites")
        let loader = DashboardLoaderStub(responses: [
            DashboardCatalog.continueQuery: .success(EntityListResponse(items: [first, second])),
            DashboardCatalog.recentQuery: .success(EntityListResponse(items: [watched])),
            DashboardCatalog.section(for: .collection)!.query: .success(EntityListResponse(items: [collection])),
        ])
        let service = DashboardService(loader: loader)

        let snapshot = await service.load()

        XCTAssertEqual(snapshot.hero, first)
        XCTAssertEqual(
            snapshot.featuredItems.map(\.id),
            [first.id, second.id]
        )
        XCTAssertEqual(snapshot.continueItems, [second])
        XCTAssertEqual(snapshot.recentItems, [watched])
        XCTAssertEqual(snapshot.sections.first { $0.kind == .collection }?.items, [collection])
        XCTAssertEqual(snapshot.state, .content)
    }

    @MainActor
    func testOneFailedShelfDoesNotDiscardSuccessfulDashboardContent() async {
        let video = item(5, kind: .video, title: "Feature")
        let loader = DashboardLoaderStub(responses: [
            DashboardCatalog.section(for: .video)!.query: .success(EntityListResponse(items: [video])),
            DashboardCatalog.section(for: .movie)!.query: .failure(.unavailable),
        ])
        let service = DashboardService(loader: loader)

        let snapshot = await service.load()

        XCTAssertEqual(snapshot.sections.first { $0.kind == .video }?.items, [video])
        XCTAssertEqual(snapshot.state, .content)
    }

    @MainActor
    func testFeaturedItemsKeepCatalogOrderAndDeduplicateEntities() async {
        let featured = item(10, kind: .movie, title: "Featured")
        let secondVideo = item(11, kind: .video, title: "Second Video")
        let loader = DashboardLoaderStub(responses: [
            DashboardCatalog.continueQuery: .success(EntityListResponse(items: [featured])),
            DashboardCatalog.recentQuery: .success(EntityListResponse(items: [featured])),
            DashboardCatalog.section(for: .movie)!.query: .success(
                EntityListResponse(items: [featured])
            ),
            DashboardCatalog.section(for: .video)!.query: .success(
                EntityListResponse(items: [secondVideo])
            ),
        ])

        let snapshot = await DashboardService(loader: loader).load()

        XCTAssertEqual(snapshot.featuredItems.map(\.id), [featured.id, secondVideo.id])
    }

    func testFeaturedSelectionUsesPlaybackHistoryAsPlayabilityEvidence() {
        let historyVideo = EntityThumbnail(
            id: UUID(),
            kind: .video,
            title: "Previously Played",
            hasSourceMedia: false,
            progress: 0.4
        )
        let playableMovie = item(12, kind: .movie, title: "Playable")
        let missingVideo = EntityThumbnail(id: UUID(), kind: .video, title: "Missing")
        let series = EntityThumbnail(
            id: UUID(),
            kind: .videoSeries,
            title: "Series",
            hasSourceMedia: true
        )
        let book = EntityThumbnail(
            id: UUID(),
            kind: .book,
            title: "Book",
            hasSourceMedia: true
        )

        let featured = DashboardFeaturedSelection.items(
            playbackHistory: [historyVideo, series, book],
            catalogSources: [[missingVideo, playableMovie]]
        )

        XCTAssertEqual(featured.map(\.id), [historyVideo.id, playableMovie.id])
    }

    @MainActor
    func testContinueShelfRemovesFeaturedItemWithoutDroppingEarlierNonplayableMedia() async {
        let audio = item(13, kind: .audioTrack, title: "Opening Theme")
        let featured = item(14, kind: .video, title: "Episode")
        let loader = DashboardLoaderStub(responses: [
            DashboardCatalog.continueQuery: .success(
                EntityListResponse(items: [audio, featured])
            )
        ])

        let snapshot = await DashboardService(loader: loader).load()

        XCTAssertEqual(snapshot.hero?.id, featured.id)
        XCTAssertEqual(snapshot.continueItems.map(\.id), [audio.id])
    }
}

private enum DashboardStubError: Error { case unavailable }

private actor DashboardLoaderStub: DashboardLoading {
    let responses: [EntityListQuery: Result<EntityListResponse, DashboardStubError>]

    init(responses: [EntityListQuery: Result<EntityListResponse, DashboardStubError>]) {
        self.responses = responses
    }

    func load(_ query: EntityListQuery, limit: Int) async throws -> EntityListResponse {
        try responses[query]?.get() ?? EntityListResponse(items: [])
    }
}

private func item(_ value: Int, kind: EntityKind, title: String) -> EntityThumbnail {
    EntityThumbnail(
        id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", value))!,
        kind: kind,
        title: title,
        hasSourceMedia: kind == .video || kind == .movie
    )
}
