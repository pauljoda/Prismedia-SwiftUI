import XCTest

@testable import PrismediaCore

final class ModeCatalogTests: XCTestCase {
    func testAudioIncludesAudioCapableCollectionsDestination() {
        let collections = ModeCatalog.audio.destination(id: "audio-collections")

        XCTAssertEqual(collections?.title, "Collections")
        XCTAssertEqual(collections?.entityList?.query.kind, .collection)
    }

    func testCatalogMatchesWebShellSections() {
        XCTAssertEqual(
            ModeCatalog.all.map(\.id),
            ["overview", "video", "images", "audio", "books", "browse", "manage", "operate"]
        )
    }

    func testManagementModesAreAdminOnly() {
        let admin = UserAccount(id: UUID(), username: "a", displayName: "A", role: .admin)
        let member = UserAccount(id: UUID(), username: "m", displayName: "M", role: .member)

        XCTAssertTrue(ModeCatalog.modes(for: admin).contains { $0.id == "manage" })
        XCTAssertTrue(ModeCatalog.modes(for: admin).contains { $0.id == "operate" })
        XCTAssertFalse(ModeCatalog.modes(for: member).contains { $0.id == "manage" })
        XCTAssertFalse(ModeCatalog.modes(for: member).contains { $0.id == "operate" })
        XCTAssertFalse(ModeCatalog.modes(for: nil).contains { $0.id == "manage" })
        XCTAssertFalse(ModeCatalog.modes(for: nil).contains { $0.id == "operate" })
    }

    func testDestinationIDsAreUniqueAcrossModes() {
        let ids = ModeCatalog.all.flatMap(\.destinations).map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count)
    }

    func testAudioModeOffersAlbumsArtistsTracksAndCollections() {
        XCTAssertEqual(
            ModeCatalog.audio.destinations.map(\.id),
            ["albums", "artists", "tracks", "audio-collections"]
        )
    }

    func testMainModesLeadWithTheirPrimaryLibraryDestination() {
        XCTAssertEqual(ModeCatalog.video.destinations.first?.id, "videos")
        XCTAssertEqual(ModeCatalog.images.destinations.first?.id, "images")
        XCTAssertEqual(ModeCatalog.audio.destinations.first?.id, "albums")
        XCTAssertEqual(ModeCatalog.books.destinations.first?.id, "books")
        XCTAssertEqual(ModeCatalog.browse.destinations.first?.id, "collections")
    }

    func testOverviewOffersDashboardCollectionsAndStats() {
        XCTAssertEqual(
            ModeCatalog.overview.destinations.map(\.id),
            ["dashboard", "overview-collections", "stats"]
        )
        XCTAssertEqual(
            ModeCatalog.overview.destination(id: "overview-collections")?.entityList?.query.kind,
            .collection
        )
    }

    func testCompactDestinationsNeverExceedFour() {
        let compactDestinations = ModeCatalog.manage.tabDestinations(selectedDestinationID: "request")

        XCTAssertLessThanOrEqual(compactDestinations.count, 4)
        XCTAssertEqual(compactDestinations.map(\.id), ["files", "identify", "request"])
    }

    func testModeContainingDestination() {
        XCTAssertEqual(ModeCatalog.mode(containing: "videos")?.id, "video")
        XCTAssertEqual(ModeCatalog.mode(containing: "files")?.id, "manage")
        XCTAssertEqual(ModeCatalog.mode(containing: "identify")?.id, "manage")
        XCTAssertEqual(ModeCatalog.mode(containing: "request")?.id, "manage")
        XCTAssertEqual(ModeCatalog.mode(containing: "settings")?.id, "operate")
        XCTAssertNil(ModeCatalog.mode(containing: "nope"))
    }

    func testOperateFlyoutIncludesTheCompleteWebNavigationSet() {
        XCTAssertEqual(
            ModeCatalog.operate.destinations.map(\.id),
            ["plugins", "jobs", "settings"]
        )
    }

    func testManageFlyoutOwnsFilesIdentifyAndRequest() {
        XCTAssertEqual(
            ModeCatalog.manage.destinations.map(\.id),
            ["files", "identify", "request"]
        )
    }

    func testLibraryDestinationsDeclareTheirEntityQueries() throws {
        let movies = try XCTUnwrap(ModeCatalog.video.destination(id: "movies"))
        let albums = try XCTUnwrap(ModeCatalog.audio.destination(id: "albums"))
        let comics = try XCTUnwrap(ModeCatalog.books.destination(id: "comics"))
        let collections = try XCTUnwrap(ModeCatalog.browse.destination(id: "collections"))

        XCTAssertEqual(movies.entityList?.query.kind, .movie)
        XCTAssertEqual(albums.entityList?.query.kind, .audioLibrary)
        XCTAssertEqual(comics.entityList?.query.bookType, "comic,manga")
        XCTAssertEqual(collections.entityList?.query.path, "/api/entities")
        XCTAssertEqual(collections.entityList?.query.kind, .collection)
        XCTAssertTrue(movies.entityList?.supportsSearch == true)
    }

    func testManagementDestinationsRemainTypedNonLibraryRoutes() {
        XCTAssertTrue(
            ModeCatalog.manage.destinations.allSatisfy {
                $0.entityList == nil && $0.manage != nil && $0.administration == nil
            })
        XCTAssertTrue(
            ModeCatalog.operate.destinations.allSatisfy {
                $0.entityList == nil && $0.manage == nil && $0.administration != nil
            })
    }

    func testEveryMainLibraryRouteUsesTheSharedEntityGridContract() throws {
        let expectedRoutes: [String: EntityListQuery] = [
            "movies": EntityListQuery(kind: .movie, sort: "added"),
            "series": EntityListQuery(kind: .videoSeries, sort: "added"),
            "videos": EntityListQuery(kind: .video, sort: "added"),
            "galleries": EntityListQuery(kind: .gallery, sort: "added"),
            "images": EntityListQuery(kind: .image, sort: "added"),
            "artists": EntityListQuery(kind: .musicArtist, sort: "added"),
            "albums": EntityListQuery(kind: .audioLibrary, sort: "added"),
            "tracks": EntityListQuery(kind: .audioTrack, sort: "added"),
            "authors": EntityListQuery(kind: .bookAuthor, sort: "added"),
            "books": EntityListQuery(kind: .book, sort: "added"),
            "comics": EntityListQuery(kind: .book, sort: "added", bookType: "comic,manga"),
            "ebooks": EntityListQuery(kind: .book, sort: "added", bookType: "book,novel", bookFormat: "epub,pdf"),
            "people": EntityListQuery(kind: .person, sort: "references"),
            "studios": EntityListQuery(kind: .studio, sort: "references"),
            "tags": EntityListQuery(kind: .tag, sort: "references"),
            "collections": EntityListQuery(kind: .collection, sort: "added"),
            "overview-collections": EntityListQuery(kind: .collection, sort: "added"),
            "audio-collections": EntityListQuery(kind: .collection, sort: "added"),
        ]

        let entityDestinations = ModeCatalog.all
            .flatMap(\.destinations)
            .filter { $0.entityList != nil }

        XCTAssertEqual(Set(entityDestinations.map(\.id)), Set(expectedRoutes.keys))

        for destination in entityDestinations {
            let entityList = try XCTUnwrap(destination.entityList)
            XCTAssertEqual(entityList.query, expectedRoutes[destination.id])
            XCTAssertTrue(entityList.supportsSearch)
        }
    }
}
