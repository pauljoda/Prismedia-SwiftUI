import XCTest

@testable import PrismediaCore

final class TVSeasonsPresentationTests: XCTestCase {
    func testSeriesSeasonsUseStructuralOrderInsteadOfResponseOrder() throws {
        let first = thumbnail(
            id: "11111111-1111-1111-1111-111111111111",
            kind: .videoSeason,
            title: "Season 1",
            order: 1
        )
        let second = thumbnail(
            id: "22222222-2222-2222-2222-222222222222",
            kind: .videoSeason,
            title: "Season 2",
            order: 2
        )
        let special = thumbnail(
            id: "33333333-3333-3333-3333-333333333333",
            kind: .videoSeason,
            title: "Specials",
            order: nil
        )
        let series = detail(
            kind: .videoSeries,
            children: [
                EntityGroup(kind: .videoSeason, label: "Seasons", entities: [second, special, first], code: nil),
                EntityGroup(kind: .studio, label: "Studios", entities: [thumbnail(kind: .studio)], code: "studio"),
            ]
        )

        XCTAssertEqual(
            TVSeasonsPresentation.seasons(in: series).map(\.id),
            [first.id, second.id, special.id]
        )
    }

    func testSeasonEpisodesUseEpisodeOrderAndIgnoreRelationships() throws {
        let first = thumbnail(
            id: "11111111-1111-1111-1111-111111111111",
            kind: .video,
            title: "Episode 1",
            order: 1
        )
        let second = thumbnail(
            id: "22222222-2222-2222-2222-222222222222",
            kind: .video,
            title: "Episode 2",
            order: 2
        )
        let season = detail(
            kind: .videoSeason,
            children: [
                EntityGroup(kind: .video, label: "Episodes", entities: [second, first], code: nil),
                EntityGroup(kind: .person, label: "Cast", entities: [thumbnail(kind: .person)], code: "cast"),
            ]
        )

        XCTAssertEqual(TVSeasonsPresentation.episodes(in: season).map(\.id), [first.id, second.id])
        XCTAssertEqual(EntityLink(thumbnail: first).parentKind, .videoSeason)
        XCTAssertEqual(EntityLink(thumbnail: first).parentEntityID, season.id)
    }

    func testSelectionSurvivesRefreshAndFallsBackToFirstSeason() {
        let first = thumbnail(
            id: "11111111-1111-1111-1111-111111111111",
            kind: .videoSeason,
            order: 1
        )
        let second = thumbnail(
            id: "22222222-2222-2222-2222-222222222222",
            kind: .videoSeason,
            order: 2
        )

        XCTAssertEqual(
            TVSeasonsPresentation.selectedSeasonID(preferredID: second.id, seasons: [first, second]),
            second.id
        )
        XCTAssertEqual(
            TVSeasonsPresentation.selectedSeasonID(preferredID: UUID(), seasons: [first, second]),
            first.id
        )
        XCTAssertNil(TVSeasonsPresentation.selectedSeasonID(preferredID: first.id, seasons: []))
    }

    func testAdjacentSeasonLookupHandlesFirstMiddleLastAndMissingSelections() {
        let first = thumbnail(kind: .videoSeason, order: 1)
        let middle = thumbnail(
            id: "22222222-2222-2222-2222-222222222222",
            kind: .videoSeason,
            order: 2
        )
        let last = thumbnail(
            id: "33333333-3333-3333-3333-333333333333",
            kind: .videoSeason,
            order: 3
        )
        let seasons = [first, middle, last]

        var adjacent = TVSeasonsPresentation.adjacentSeasons(selectedID: first.id, seasons: seasons)
        XCTAssertNil(adjacent.previous)
        XCTAssertEqual(adjacent.next?.id, middle.id)

        adjacent = TVSeasonsPresentation.adjacentSeasons(selectedID: middle.id, seasons: seasons)
        XCTAssertEqual(adjacent.previous?.id, first.id)
        XCTAssertEqual(adjacent.next?.id, last.id)

        adjacent = TVSeasonsPresentation.adjacentSeasons(selectedID: last.id, seasons: seasons)
        XCTAssertEqual(adjacent.previous?.id, middle.id)
        XCTAssertNil(adjacent.next)

        adjacent = TVSeasonsPresentation.adjacentSeasons(selectedID: UUID(), seasons: seasons)
        XCTAssertNil(adjacent.previous)
        XCTAssertNil(adjacent.next)
    }

    func testPlaybackRouteSelectsItsExactEpisodeWithinTheSeason() {
        let first = thumbnail(kind: .video, order: 1)
        let requested = thumbnail(
            id: "22222222-2222-2222-2222-222222222222",
            kind: .video,
            order: 2
        )
        let route = EntityLink(
            thumbnail: EntityThumbnail(
                id: requested.id,
                kind: .video,
                title: requested.title,
                parentEntityID: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!,
                parentKind: .videoSeason
            ),
            intent: .playback
        )

        XCTAssertEqual(
            TVSeasonsPresentation.routeEpisode(from: route, episodes: [first, requested])?.id,
            requested.id
        )
        XCTAssertNil(
            TVSeasonsPresentation.routeEpisode(
                from: EntityLink(thumbnail: requested, intent: .detail),
                episodes: [first, requested]
            )
        )
    }

    func testHierarchyProjectionRejectsTheWrongDetailLevel() {
        let season = thumbnail(kind: .videoSeason, order: 1)
        let episode = thumbnail(kind: .video, order: 1)
        let movie = detail(
            kind: .movie,
            children: [
                EntityGroup(kind: .videoSeason, label: "Seasons", entities: [season], code: nil),
                EntityGroup(kind: .video, label: "Videos", entities: [episode], code: nil),
            ]
        )

        XCTAssertTrue(TVSeasonsPresentation.seasons(in: movie).isEmpty)
        XCTAssertTrue(TVSeasonsPresentation.episodes(in: movie).isEmpty)
    }

    func testFocusingAnUncachedEpisodePrewarmsWithoutAutoplay() {
        let episodeID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!

        XCTAssertEqual(
            TVSeasonsPresentation.episodeSelection(
                episodeID: episodeID,
                intent: .focus,
                isDetailCached: false
            ),
            TVEpisodeSelectionDecision(
                episodeID: episodeID,
                shouldPrewarmDetail: true,
                shouldAutoPlay: false
            )
        )
    }

    func testActivatingACachedEpisodeAutoplaysWithoutRedundantPrewarm() {
        let episodeID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

        XCTAssertEqual(
            TVSeasonsPresentation.episodeSelection(
                episodeID: episodeID,
                intent: .activate,
                isDetailCached: true
            ),
            TVEpisodeSelectionDecision(
                episodeID: episodeID,
                shouldPrewarmDetail: false,
                shouldAutoPlay: true
            )
        )
    }

    func testFocusingACachedEpisodeUsesCacheWithoutAutoplay() {
        let episodeID = UUID()

        XCTAssertEqual(
            TVSeasonsPresentation.episodeSelection(
                episodeID: episodeID,
                intent: .focus,
                isDetailCached: true
            ),
            TVEpisodeSelectionDecision(
                episodeID: episodeID,
                shouldPrewarmDetail: false,
                shouldAutoPlay: false
            )
        )
    }

    func testActivatingAnUncachedEpisodeLoadsThenAutoplays() {
        let episodeID = UUID()

        XCTAssertEqual(
            TVSeasonsPresentation.episodeSelection(
                episodeID: episodeID,
                intent: .activate,
                isDetailCached: false
            ),
            TVEpisodeSelectionDecision(
                episodeID: episodeID,
                shouldPrewarmDetail: true,
                shouldAutoPlay: true
            )
        )
    }

    private func detail(
        kind: EntityKind,
        children: [EntityGroup]
    ) -> EntityDetail {
        EntityDetail(
            id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!,
            kind: kind,
            title: "Reference",
            parentEntityID: nil,
            sortOrder: nil,
            hasSourceMedia: true,
            capabilities: [],
            childrenByKind: children,
            relationships: []
        )
    }

    private func thumbnail(
        id: String = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
        kind: EntityKind,
        title: String = "Reference",
        order: Int? = nil
    ) -> EntityThumbnail {
        let parentID =
            kind == .video
            ? UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")
            : nil
        let parentKind: EntityKind? = kind == .video ? .videoSeason : nil

        return EntityThumbnail(
            id: UUID(uuidString: id)!,
            kind: kind,
            title: title,
            parentEntityID: parentID,
            parentKind: parentKind,
            sortOrder: order,
            hasSourceMedia: true
        )
    }
}

@MainActor
final class TVSeasonsUseCaseTests: XCTestCase {
    func testOpeningASeasonLoadsItsParentSeriesWithoutReplacingUsableSeasonContent() async throws {
        let seriesID = UUID(uuidString: "10000000-0000-0000-0000-000000000001")!
        let seasonID = UUID(uuidString: "20000000-0000-0000-0000-000000000001")!
        let episode = EntityThumbnail(
            id: UUID(uuidString: "30000000-0000-0000-0000-000000000001")!,
            kind: .video,
            title: "Episode 1",
            parentEntityID: seasonID,
            parentKind: .videoSeason,
            sortOrder: 1
        )
        let seasonThumbnail = EntityThumbnail(
            id: seasonID,
            kind: .videoSeason,
            title: "Season 1",
            parentEntityID: seriesID,
            sortOrder: 1
        )
        let series = EntityDetail(
            id: seriesID,
            kind: .videoSeries,
            title: "Series",
            parentEntityID: nil,
            sortOrder: nil,
            hasSourceMedia: false,
            capabilities: [],
            childrenByKind: [.init(kind: .videoSeason, label: "Seasons", entities: [seasonThumbnail], code: nil)],
            relationships: []
        )
        let season = EntityDetail(
            id: seasonID,
            kind: .videoSeason,
            title: "Season 1",
            parentEntityID: seriesID,
            sortOrder: 1,
            hasSourceMedia: false,
            capabilities: [],
            childrenByKind: [.init(kind: .video, label: "Episodes", entities: [episode], code: nil)],
            relationships: []
        )
        let loader = TVSeasonsLoaderStub(values: [seriesID: series])
        let useCase = TVSeasonsUseCase(rootDetail: season, loader: loader)

        let initial = useCase.initialSnapshot
        let parent = try await useCase.loadParentSeries()
        let requestedIDs = await loader.requestedIDs()

        XCTAssertEqual(initial.selectedSeasonID, seasonID)
        XCTAssertEqual(initial.episodes.map(\.id), [episode.id])
        XCTAssertEqual(parent?.id, seriesID)
        XCTAssertEqual(requestedIDs, [seriesID])
    }
}

private actor TVSeasonsLoaderStub: EntityDetailLoading {
    let values: [UUID: EntityDetail]
    private var requests: [UUID] = []

    init(values: [UUID: EntityDetail]) {
        self.values = values
    }

    func loadEntity(id: UUID) async throws -> EntityDetail {
        requests.append(id)
        guard let value = values[id] else { throw TVSeasonsLoaderStubError.missing }
        return value
    }

    func requestedIDs() -> [UUID] { requests }
}

private enum TVSeasonsLoaderStubError: Error { case missing }
