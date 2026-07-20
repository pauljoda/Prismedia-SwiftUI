import SwiftUI
import XCTest

@testable import PrismediaCore

final class AppShellNavigationTests: XCTestCase {
    func testLandscapePhoneKeepsCompactShellDuringFullscreenPlayback() {
        XCTAssertFalse(
            AppShellLayoutPolicy.usesWideShell(
                horizontalSizeClass: .regular,
                verticalSizeClass: .compact
            )
        )
        XCTAssertTrue(
            AppShellLayoutPolicy.usesWideShell(
                horizontalSizeClass: .regular,
                verticalSizeClass: .regular
            )
        )
    }

    func testSidebarCatalogMatchesTheWebNavigationHierarchy() {
        let sections = AppSidebarCatalog.sections(for: PrismediaPreviewData.user)

        XCTAssertEqual(
            sections.map(\.title),
            ["Overview", "Video", "Images", "Audio", "Books", "Browse", "Operate"]
        )
        XCTAssertEqual(
            sections[0].items.map(\.title),
            ["Dashboard", "Favorites", "Search", "Stats"]
        )
        XCTAssertEqual(
            ModeCatalog.overview.destinations.map(\.title),
            ["Dashboard", "Collections", "Favorites", "Stats"]
        )
        XCTAssertNil(ModeCatalog.overview.destination(id: "account"))
        XCTAssertEqual(sections[1].items.map(\.title), ["Movies", "Series", "Videos"])
        XCTAssertEqual(sections[2].items.map(\.title), ["Galleries", "Images"])
        XCTAssertEqual(sections[3].items.map(\.title), ["Artists", "Audio"])
        XCTAssertEqual(sections[4].items.map(\.title), ["Authors", "Books", "Comics", "eBooks"])
        XCTAssertEqual(
            sections[5].items.map(\.title),
            ["People", "Studios", "Tags", "Collections"]
        )
        XCTAssertEqual(
            sections[6].items.map(\.title),
            ["Files", "Identify", "Request", "Plugins", "Jobs", "Settings"]
        )
    }

    func testSidebarCatalogHidesOperateFromNonAdministrators() {
        let user = UserAccount(
            id: UUID(),
            username: "viewer",
            displayName: "Viewer",
            role: .member
        )

        XCTAssertEqual(
            AppSidebarCatalog.sections(for: user).map(\.title),
            ["Overview", "Video", "Images", "Audio", "Books", "Browse"]
        )
    }

    func testLibraryCreatorsReceiveOnlyTheDedicatedManagementEntry() {
        let user = UserAccount(
            id: UUID(),
            username: "curator",
            displayName: "Curator",
            role: .member,
            canCreateLibraries: true
        )

        XCTAssertEqual(ModeCatalog.modes(for: user).last?.id, "library-management")
        XCTAssertEqual(AppSidebarCatalog.sections(for: user).last?.title, "Manage")
        XCTAssertEqual(AppSidebarCatalog.sections(for: user).last?.items.map(\.title), ["Settings"])
        XCTAssertFalse(ModeCatalog.modes(for: user).contains(where: { $0.id == "operate" }))
    }

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
                XCTAssertTrue(dashboard.query.sortDescending)

                guard case .entityList(let entityList) = canonical.destination.content else {
                    return XCTFail("Canonical destination for \(kind.rawValue) must be an entity list")
                }
                XCTAssertEqual(entityList.query.sort, "added")
                XCTAssertTrue(entityList.query.sortDescending)
            }
        }
    }

    func testRootEntityLibrariesDefaultToNewestAdded() {
        let rootLibraries = ModeCatalog.all
            .flatMap(\.destinations)
            .compactMap { destination -> (AppDestination, EntityListDestination)? in
                guard case .entityList(let entityList) = destination.content else { return nil }
                return (destination, entityList)
            }

        XCTAssertFalse(rootLibraries.isEmpty)
        for (destination, entityList) in rootLibraries {
            XCTAssertEqual(entityList.query.sort, "added", destination.id)
            XCTAssertTrue(entityList.query.sortDescending, destination.id)
        }

        for tab in TVAppCatalog.tabs where tab.query != nil {
            XCTAssertEqual(tab.query?.sort, "added", tab.id)
            XCTAssertEqual(tab.query?.sortDescending, true, tab.id)
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
    func testFavoritesUseOneMixedPathForKindGridsAndEntityDetails() throws {
        let router = PrismediaAppRouter(
            initialMode: ModeCatalog.overview,
            initialDestinationID: PrismediaAppRouter.favoritesPathID
        )
        var path = NavigationPath()
        path.append(try XCTUnwrap(FavoritesCatalog.sections.first))
        router.setFavoritesPath(path)

        router.open(
            entity: EntityThumbnail(id: UUID(), kind: .video, title: "Favorite Video")
        )

        XCTAssertEqual(router.favoritesPath.count, 2)
        XCTAssertTrue(router.path(for: PrismediaAppRouter.favoritesPathID).isEmpty)
        XCTAssertTrue(router.navigateBack(in: PrismediaAppRouter.favoritesPathID))
        XCTAssertEqual(router.favoritesPath.count, 1)
    }

    @MainActor
    func testAppRouterKeepsSearchFiltersAcrossSearchDetailNavigation() {
        let router = PrismediaAppRouter(initialSearchSelected: true)
        let filters = SearchHubFilterState(
            selectedKinds: [.movie, .video],
            minimumRating: 4,
            dateFrom: Date(timeIntervalSince1970: 1_735_689_600)
        )
        router.searchText = "matrix"
        router.searchFilters = filters

        router.open(entity: EntityThumbnail(id: UUID(), kind: .movie, title: "The Matrix"))
        _ = router.navigateBack(in: PrismediaAppRouter.searchPathID)

        XCTAssertEqual(router.searchText, "matrix")
        XCTAssertEqual(router.searchFilters, filters)
    }

    @MainActor
    func testResetRemovesAllAccountNavigationAndSearchState() {
        let router = PrismediaAppRouter(
            initialMode: ModeCatalog.video,
            initialDestinationID: "movies",
            initialSearchSelected: true
        )
        router.searchText = "private search"
        router.searchFilters = SearchHubFilterState(selectedKinds: [.movie])
        router.setPath([EntityLink(entityID: UUID(), kind: .movie)], for: "movies")
        router.onWillOpenEntity = {}

        router.reset()

        XCTAssertEqual(router.navigation.modeID, "overview")
        XCTAssertEqual(router.navigation.destinationID, "dashboard")
        XCTAssertEqual(router.selectedTab, .destination("dashboard"))
        XCTAssertEqual(router.searchText, "")
        XCTAssertEqual(router.searchFilters, SearchHubFilterState())
        XCTAssertTrue(router.path(for: "movies").isEmpty)
        XCTAssertNil(router.onWillOpenEntity)
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
