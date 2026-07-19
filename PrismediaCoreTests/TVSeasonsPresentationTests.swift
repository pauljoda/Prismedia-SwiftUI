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

    func testEpisodeSelectionCoordinatesCachingAndFullscreenPresentation() {
        let episodeID = UUID()
        let cases:
            [(
                intent: TVEpisodeSelectionIntent,
                isDetailCached: Bool,
                shouldPrewarm: Bool,
                shouldPresentFullscreen: Bool
            )] = [
                (.focus, false, true, false),
                (.focus, true, false, false),
                (.activate, false, true, true),
                (.activate, true, false, true),
            ]

        for testCase in cases {
            XCTAssertEqual(
                TVSeasonsPresentation.episodeSelection(
                    episodeID: episodeID,
                    intent: testCase.intent,
                    isDetailCached: testCase.isDetailCached
                ),
                TVEpisodeSelectionDecision(
                    episodeID: episodeID,
                    shouldPrewarmDetail: testCase.shouldPrewarm,
                    shouldPresentFullscreen: testCase.shouldPresentFullscreen
                )
            )
        }
    }

    func testInstallingASeasonSelectsThePreferredProgressEpisode() {
        let first = thumbnail(kind: .video, order: 1)
        let progressEpisode = thumbnail(
            id: "22222222-2222-2222-2222-222222222222",
            kind: .video,
            order: 2
        )
        let season = detail(
            kind: .videoSeason,
            children: [
                EntityGroup(
                    kind: .video,
                    label: "Episodes",
                    entities: [first, progressEpisode],
                    code: nil
                )
            ]
        )
        var snapshot = TVSeasonsSnapshot()

        snapshot.installSeason(season, preferredEpisodeID: progressEpisode.id)

        XCTAssertEqual(snapshot.selectedEpisode?.id, progressEpisode.id)
    }

    func testEpisodeDescriptionPrefersLoadedEpisodeDetail() {
        let episode = thumbnail(kind: .video, order: 1)
        let episodeDetail = detail(
            kind: .video,
            children: [],
            description: "The episode-specific description."
        )

        XCTAssertEqual(
            TVEpisodeDescriptionPresentation.text(
                episode: episode,
                episodeDetail: episodeDetail,
                seriesDescription: "The series description."
            ),
            "The episode-specific description."
        )
    }

    func testEpisodeDescriptionFallsBackFromThumbnailToSeries() {
        let episode = thumbnail(kind: .video, order: 1, summary: "Episode summary")

        XCTAssertEqual(
            TVEpisodeDescriptionPresentation.text(
                episode: episode,
                episodeDetail: nil,
                seriesDescription: "Series description"
            ),
            "Episode summary"
        )
        XCTAssertEqual(
            TVEpisodeDescriptionPresentation.text(
                episode: thumbnail(kind: .video, order: 1),
                episodeDetail: nil,
                seriesDescription: "Series description"
            ),
            "Series description"
        )
    }

    func testRefreshingASeasonPreservesSelectionAndUpdatesEpisodeProgress() {
        let selectedID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let first = thumbnail(kind: .video, order: 1)
        let selected = thumbnail(
            id: selectedID.uuidString,
            kind: .video,
            order: 2
        )
        let refreshedSelected = thumbnail(
            id: selectedID.uuidString,
            kind: .video,
            order: 2,
            progress: 0.64,
            resumeSeconds: 1_800
        )
        var snapshot = TVSeasonsSnapshot()
        snapshot.installSeason(
            detail(
                kind: .videoSeason,
                children: [.init(kind: .video, label: "Episodes", entities: [first, selected], code: nil)]
            ),
            preferredEpisodeID: selectedID
        )

        snapshot.refreshSeason(
            detail(
                kind: .videoSeason,
                children: [
                    .init(kind: .video, label: "Episodes", entities: [first, refreshedSelected], code: nil)
                ]
            )
        )

        XCTAssertEqual(snapshot.selectedEpisode?.id, selectedID)
        XCTAssertEqual(snapshot.selectedEpisode?.progress, 0.64)
        XCTAssertEqual(snapshot.selectedEpisode?.resumeSeconds, 1_800)
    }

    func testDelayedFullscreenDismissalCannotClearNewPlaybackRequest() {
        let first = TVEpisodePlaybackRequest(episodeID: UUID())
        let second = TVEpisodePlaybackRequest(episodeID: UUID())
        var snapshot = TVSeasonsSnapshot()

        snapshot.presentFullscreen(first)
        snapshot.presentFullscreen(second)
        snapshot.finishFullscreen(requestID: first.id)

        XCTAssertEqual(snapshot.fullscreenRequest, second)

        snapshot.finishFullscreen(requestID: second.id)

        XCTAssertNil(snapshot.fullscreenRequest)
    }

    private func detail(
        kind: EntityKind,
        children: [EntityGroup],
        description: String? = nil
    ) -> EntityDetail {
        EntityDetail(
            id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!,
            kind: kind,
            title: "Reference",
            parentEntityID: nil,
            sortOrder: nil,
            hasSourceMedia: true,
            capabilities: description.map {
                [.description(EntityDescriptionCapability(value: $0))]
            } ?? [],
            childrenByKind: children,
            relationships: []
        )
    }

    private func thumbnail(
        id: String = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
        kind: EntityKind,
        title: String = "Reference",
        order: Int? = nil,
        summary: String? = nil,
        progress: Double? = nil,
        resumeSeconds: Double? = nil
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
            summary: summary,
            parentEntityID: parentID,
            parentKind: parentKind,
            sortOrder: order,
            hasSourceMedia: true,
            progress: progress,
            resumeSeconds: resumeSeconds
        )
    }
}

@MainActor
final class TVSeasonsUseCaseTests: XCTestCase {
    func testSeriesProgressTargetResolvesTheEpisodeSeason() async throws {
        let seriesID = UUID(uuidString: "10000000-0000-0000-0000-000000000001")!
        let seasonID = UUID(uuidString: "20000000-0000-0000-0000-000000000002")!
        let episodeID = UUID(uuidString: "30000000-0000-0000-0000-000000000003")!
        let seasonThumbnail = EntityThumbnail(
            id: seasonID,
            kind: .videoSeason,
            title: "Season 2",
            parentEntityID: seriesID,
            sortOrder: 2
        )
        let series = EntityDetail(
            id: seriesID,
            kind: .videoSeries,
            title: "Series",
            parentEntityID: nil,
            sortOrder: nil,
            hasSourceMedia: false,
            capabilities: [
                .progress(
                    EntityProgressCapability(
                        currentEntityID: episodeID,
                        unit: .item,
                        index: 4,
                        total: 12,
                        mode: nil,
                        completedAt: nil,
                        updatedAt: nil,
                        workIndex: nil,
                        workTotal: nil,
                        location: nil
                    )
                )
            ],
            childrenByKind: [
                .init(kind: .videoSeason, label: "Seasons", entities: [seasonThumbnail], code: nil)
            ],
            relationships: []
        )
        let episode = EntityDetail(
            id: episodeID,
            kind: .video,
            title: "Current Episode",
            parentEntityID: seasonID,
            sortOrder: 5,
            hasSourceMedia: true,
            capabilities: [],
            childrenByKind: [],
            relationships: []
        )
        let loader = TVSeasonsLoaderStub(values: [episodeID: episode])
        let useCase = TVSeasonsUseCase(rootDetail: series, loader: loader)

        let target = try await useCase.loadProgressTarget()
        let requestedIDs = await loader.requestedIDs()

        XCTAssertEqual(target?.episodeID, episodeID)
        XCTAssertEqual(target?.seasonID, seasonID)
        XCTAssertEqual(requestedIDs, [episodeID])
    }

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
