import XCTest

@testable import PrismediaCore

final class AppShellNavigationTests: XCTestCase {
    func testCanonicalEntityDestinationsDriveSearchAndDashboardPresentation() throws {
        let expectedDestinationIDs: [EntityKind: String] = [
            .video: "videos",
            .movie: "movies",
            .videoSeries: "series",
            .videoSeason: "series",
            .image: "images",
            .gallery: "galleries",
            .audioLibrary: "albums",
            .musicArtist: "artists",
            .audioTrack: "tracks",
            .book: "books",
            .bookAuthor: "authors",
            .bookChapter: "books",
            .bookPage: "books",
            .collection: "collections",
            .person: "people",
            .studio: "studios",
            .tag: "tags",
        ]

        for (kind, expectedDestinationID) in expectedDestinationIDs {
            let canonical = try XCTUnwrap(ModeCatalog.canonicalDestination(for: kind))
            let search = try XCTUnwrap(SearchHubCatalog.navigationTarget(for: kind))

            XCTAssertEqual(canonical.destination.id, expectedDestinationID)
            XCTAssertEqual(search.mode.id, canonical.mode.id)
            XCTAssertEqual(search.destination, canonical.destination)

            if let dashboard = DashboardCatalog.section(for: kind) {
                XCTAssertEqual(dashboard.title, canonical.destination.title)
                XCTAssertEqual(
                    dashboard.systemImage,
                    kind == .audioLibrary ? "waveform" : canonical.destination.systemImage
                )
                XCTAssertEqual(dashboard.destinationID, canonical.destination.id)
            }
        }
    }

    func testReconcileMovesAnUnavailableAdminRouteToOverview() {
        var navigation = AppShellNavigation(mode: ModeCatalog.operate, destinationID: "settings")

        navigation.reconcile(with: ModeCatalog.modes(for: nil))

        XCTAssertEqual(navigation.modeID, "overview")
        XCTAssertEqual(navigation.destinationID, "dashboard")
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
        XCTAssertEqual(router.path(for: "series"), [episodeLink])
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
            EntityImageViewerRouteSessionFactory.make(for: routeLink, sequenceLoader: nil)
        )
        session.select(third.id)

        var path = [routeLink]
        path.append(EntityLink(thumbnail: try XCTUnwrap(session.currentItem), intent: .metadata))
        _ = path.popLast()

        XCTAssertEqual(path, [routeLink])
        XCTAssertEqual(session.currentEntityID, third.id)
        XCTAssertEqual(session.currentItem, third)
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
        XCTAssertNil(PrismediaEntityDeepLink.link(from: URL(string: "javascript:alert(1)")!))
    }
}
