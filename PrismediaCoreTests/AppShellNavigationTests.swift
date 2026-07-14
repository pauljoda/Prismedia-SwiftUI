import XCTest

@testable import PrismediaCore

final class AppShellNavigationTests: XCTestCase {
    func testSwitchingToAudioSelectsItsFirstDestination() {
        var navigation = AppShellNavigation(mode: ModeCatalog.overview, destinationID: "stats")

        navigation.select(mode: ModeCatalog.audio)

        XCTAssertEqual(navigation.modeID, "audio")
        XCTAssertEqual(navigation.destinationID, "albums")
    }

    func testReturningToASectionRestoresItsLastDestination() {
        var navigation = AppShellNavigation(mode: ModeCatalog.audio, destinationID: "albums")
        navigation.select(mode: ModeCatalog.video, destination: ModeCatalog.video.destinations[1])

        navigation.select(mode: ModeCatalog.audio)

        XCTAssertEqual(navigation.destinationID, "albums")
    }

    func testSelectingADestinationAlsoSelectsItsMode() {
        var navigation = AppShellNavigation(mode: ModeCatalog.overview)
        let tracks = ModeCatalog.audio.destinations[2]

        navigation.select(mode: ModeCatalog.audio, destination: tracks)

        XCTAssertEqual(navigation.modeID, "audio")
        XCTAssertEqual(navigation.destinationID, "tracks")
    }

    func testReconcileMovesAnUnavailableAdminRouteToOverview() {
        var navigation = AppShellNavigation(mode: ModeCatalog.operate, destinationID: "settings")

        navigation.reconcile(with: ModeCatalog.modes(for: nil))

        XCTAssertEqual(navigation.modeID, "overview")
        XCTAssertEqual(navigation.destinationID, "dashboard")
    }

    func testInvalidInitialDestinationFallsBackToTheModeDefault() {
        let navigation = AppShellNavigation(mode: ModeCatalog.video, destinationID: "not-a-video-tab")

        XCTAssertEqual(navigation.destinationID, "videos")
    }

    @MainActor
    func testAppRouterOwnsInitialTabAndPerDestinationPaths() {
        let router = PrismediaAppRouter(
            initialMode: ModeCatalog.video,
            initialDestinationID: "movies",
            initialSearchSelected: true
        )
        let link = EntityLink(
            entityID: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!,
            kind: .movie
        )

        router.setPath([link], for: "movies")

        XCTAssertEqual(router.selectedTab, .search)
        XCTAssertEqual(router.path(for: "movies"), [link])
        XCTAssertEqual(router.activeMode(in: ModeCatalog.all).id, "video")
    }

    @MainActor
    func testAppRouterSelectsTheDestinationAndPreservesItsMode() {
        let router = PrismediaAppRouter()
        let tracks = ModeCatalog.audio.destinations[2]

        router.select(mode: ModeCatalog.audio, destination: tracks)

        XCTAssertEqual(router.selectedTab, .destination("tracks"))
        XCTAssertEqual(router.navigation.modeID, "audio")
        XCTAssertEqual(router.navigation.destinationID, "tracks")
    }

    @MainActor
    func testAppRouterOpensAnEntityInTheCurrentlySelectedDestinationStack() {
        let router = PrismediaAppRouter(
            initialMode: ModeCatalog.video,
            initialDestinationID: "movies"
        )
        let entity = EntityThumbnail(id: UUID(), kind: .movie, title: "Arrival")

        router.open(entity: entity, previewSubtitle: "Science fiction")

        XCTAssertEqual(router.path(for: "movies"), [EntityLink(thumbnail: entity)])
        XCTAssertEqual(router.path(for: "movies").last?.previewSubtitle, "Science fiction")
    }

    @MainActor
    func testEpisodePlaybackUsesItsSeasonAsThePlayerRoute() {
        let router = PrismediaAppRouter(
            initialMode: ModeCatalog.video,
            initialDestinationID: "series"
        )
        let seasonID = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
        let episode = EntityThumbnail(
            id: UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!,
            kind: .video,
            title: "Episode Two",
            parentEntityID: seasonID,
            parentKind: .videoSeason
        )

        router.open(entity: episode, intent: .playback)

        XCTAssertEqual(
            router.path(for: "series"),
            [EntityLink(thumbnail: episode, intent: .playback)]
        )
    }

    @MainActor
    func testEpisodePlaybackPushesAPlaybackOwnedSeasonOverAnAlreadyOpenSeason() {
        let router = PrismediaAppRouter(
            initialMode: ModeCatalog.video,
            initialDestinationID: "series"
        )
        let seasonID = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
        let season = EntityThumbnail(
            id: seasonID,
            kind: .videoSeason,
            title: "Season One"
        )
        let episode = EntityThumbnail(
            id: UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!,
            kind: .video,
            title: "Episode Two",
            parentEntityID: seasonID,
            parentKind: .videoSeason
        )

        router.open(entity: season)
        router.open(entity: episode, intent: .playback)

        XCTAssertEqual(
            router.path(for: "series"),
            [
                EntityLink(thumbnail: season),
                EntityLink(thumbnail: episode, intent: .playback),
            ]
        )
    }

    @MainActor
    func testRestoringEpisodePlaybackUsesTheSeriesStackAndPreservesSeasonReturn() async {
        let router = PrismediaAppRouter()
        let seasonID = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
        let episode = EntityThumbnail(
            id: UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!,
            kind: .video,
            title: "Episode Two",
            parentEntityID: seasonID,
            parentKind: .videoSeason
        )
        let episodeLink = EntityLink(thumbnail: episode, intent: .playback)

        await router.restoreVideoPlayback(episodeLink)

        XCTAssertEqual(router.selectedTab, .destination("series"))
        XCTAssertEqual(
            router.path(for: "series"),
            [episodeLink]
        )
    }

    @MainActor
    func testAppRouterNavigatesBackWithinOnlyTheRequestedDestinationStack() {
        let router = PrismediaAppRouter(
            initialMode: ModeCatalog.video,
            initialDestinationID: "movies"
        )
        let first = EntityLink(entityID: UUID(), kind: .movie)
        let second = EntityLink(entityID: UUID(), kind: .movie)
        let untouched = EntityLink(entityID: UUID(), kind: .video)
        router.setPath([first, second], for: "movies")
        router.setPath([untouched], for: "videos")

        XCTAssertTrue(router.navigateBack(in: "movies"))

        XCTAssertEqual(router.path(for: "movies"), [first])
        XCTAssertEqual(router.path(for: "videos"), [untouched])
    }

    @MainActor
    func testAppRouterDoesNotNavigateBackFromAnEmptyDestinationStack() {
        let router = PrismediaAppRouter()

        XCTAssertFalse(router.navigateBack(in: "dashboard"))
        XCTAssertTrue(router.path(for: "dashboard").isEmpty)
    }

    @MainActor
    func testAppRouterPerformsSynchronousPlaybackHandoffBeforeOpeningEntity() {
        let router = PrismediaAppRouter(initialMode: ModeCatalog.video, initialDestinationID: "movies")
        let entity = EntityThumbnail(id: UUID(), kind: .movie, title: "Arrival")
        var pathWasEmptyDuringHandoff = false
        router.onWillOpenEntity = {
            pathWasEmptyDuringHandoff = router.path(for: "movies").isEmpty
        }

        router.open(entity: entity)

        XCTAssertTrue(pathWasEmptyDuringHandoff)
        XCTAssertEqual(router.path(for: "movies"), [EntityLink(thumbnail: entity)])
    }

    @MainActor
    func testAppRouterOpensAnEntityInTheSearchStackWhenSearchIsSelected() {
        let router = PrismediaAppRouter(initialSearchSelected: true)
        let entity = EntityThumbnail(id: UUID(), kind: .book, title: "Dune")

        router.open(entity: entity)

        XCTAssertEqual(router.path(for: PrismediaAppRouter.searchPathID), [EntityLink(thumbnail: entity)])
    }

    @MainActor
    func testAppRouterCarriesImageSequenceWithoutChangingDestinationIdentity() {
        let router = PrismediaAppRouter(initialMode: ModeCatalog.images, initialDestinationID: "images")
        let first = EntityThumbnail(id: UUID(), kind: .image, title: "First")
        let second = EntityThumbnail(id: UUID(), kind: .image, title: "Second")
        let sequence = EntityMediaSequence(items: [first, second])

        router.open(entity: second, within: sequence)

        XCTAssertEqual(router.path(for: "images").last?.entityID, second.id)
        XCTAssertEqual(router.path(for: "images").last?.mediaSequence, sequence)
    }

    @MainActor
    func testImageViewerRouteSessionPreservesSelectionAcrossMetadataRoundTrip() throws {
        let first = EntityThumbnail(id: UUID(), kind: .image, title: "First")
        let second = EntityThumbnail(id: UUID(), kind: .image, title: "Second")
        let third = EntityThumbnail(id: UUID(), kind: .image, title: "Third")
        let routeLink = EntityLink(
            thumbnail: first,
            mediaSequence: EntityMediaSequence(items: [first, second, third])
        )
        let session = try XCTUnwrap(
            EntityImageViewerRouteSessionFactory.make(
                for: routeLink,
                sequenceLoader: nil
            )
        )
        session.select(third.id)

        var path = [routeLink]
        path.append(
            EntityLink(
                thumbnail: try XCTUnwrap(session.currentItem),
                intent: .metadata
            )
        )
        _ = path.popLast()

        XCTAssertEqual(path, [routeLink])
        XCTAssertEqual(session.currentEntityID, third.id)
        XCTAssertEqual(session.currentItem, third)
    }

    @MainActor
    func testDirectImageRouteSynthesizesAViewerSessionForUITestBootstrap() throws {
        let imageID = UUID()
        let link = EntityLink(entityID: imageID, kind: .image)

        let session = try XCTUnwrap(
            EntityImageViewerRouteSessionFactory.make(
                for: link,
                sequenceLoader: nil
            )
        )

        XCTAssertEqual(session.currentEntityID, imageID)
        XCTAssertEqual(session.sequence.items.map(\.id), [imageID])
        XCTAssertEqual(session.currentItem?.title, "Image")
    }

    func testEntityDeepLinksParseCustomAndWebRoutesIntoTypedStackValues() throws {
        let id = UUID(uuidString: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee")!
        let custom = try XCTUnwrap(
            PrismediaEntityDeepLink.link(
                from: URL(string: "prismedia://entity/image/\(id.uuidString)")!
            )
        )
        let web = try XCTUnwrap(
            PrismediaEntityDeepLink.link(
                from: URL(string: "https://media.example/albums/\(id.uuidString)?intent=play")!
            )
        )

        XCTAssertEqual(custom, EntityLink(entityID: id, kind: .image))
        XCTAssertEqual(web, EntityLink(entityID: id, kind: .audioLibrary, intent: .playback))
        XCTAssertNil(
            PrismediaEntityDeepLink.link(from: URL(string: "javascript:alert(1)")!)
        )
    }

    @MainActor
    func testRouterPushesTypedDeepLinkIntoTheCurrentStack() {
        let router = PrismediaAppRouter(initialMode: ModeCatalog.books, initialDestinationID: "books")
        let link = EntityLink(entityID: UUID(), kind: .book)

        router.open(link: link)

        XCTAssertEqual(router.path(for: "books"), [link])
    }
}
