import XCTest

@testable import PrismediaCore

final class PrismediaUITestBootstrapTests: XCTestCase {
    func testMockSessionRequiresTheExplicitUITestingFlag() {
        let environment = [
            "PRISMEDIA_UI_TEST_SESSION_SERVER": "http://localhost:8899",
            "PRISMEDIA_UI_TEST_SESSION_TOKEN": "mock-session-token",
        ]

        XCTAssertNil(
            PrismediaUITestBootstrap.session(
                arguments: [],
                environment: environment
            )
        )
    }

    func testMockSessionUsesLaunchEnvironmentValues() throws {
        let session = try XCTUnwrap(
            PrismediaUITestBootstrap.session(
                arguments: ["-prismedia-ui-testing"],
                environment: [
                    "PRISMEDIA_UI_TEST_SESSION_SERVER": "http://localhost:8899",
                    "PRISMEDIA_UI_TEST_SESSION_TOKEN": "mock-session-token",
                ]
            )
        )

        XCTAssertEqual(session.serverURL.absoluteString, "http://localhost:8899")
        XCTAssertEqual(session.accessToken, "mock-session-token")
        XCTAssertEqual(session.user.role, .admin)
    }

    @MainActor
    func testInitialCollectionEntityConfiguresTheSharedCollectionRoute() throws {
        let entityID = UUID()
        let router = try XCTUnwrap(
            PrismediaUITestBootstrap.router(
                arguments: ["-prismedia-ui-testing"],
                environment: [
                    "PRISMEDIA_UI_TEST_ENTITY_ID": entityID.uuidString,
                    "PRISMEDIA_UI_TEST_ENTITY_KIND": "collection",
                ]
            )
        )

        XCTAssertEqual(router.navigation.modeID, ModeCatalog.browse.id)
        XCTAssertEqual(router.navigation.destinationID, "collections")
        XCTAssertEqual(router.path(for: "collections").map(\.entityID), [entityID])
    }

    @MainActor
    func testInitialBookEntityConfiguresTheNativeBooksRoute() throws {
        let entityID = UUID()
        let router = try XCTUnwrap(
            PrismediaUITestBootstrap.router(
                arguments: ["-prismedia-ui-testing"],
                environment: [
                    "PRISMEDIA_UI_TEST_ENTITY_ID": entityID.uuidString,
                    "PRISMEDIA_UI_TEST_ENTITY_KIND": "book",
                ]
            )
        )

        XCTAssertEqual(router.navigation.modeID, ModeCatalog.books.id)
        XCTAssertEqual(router.navigation.destinationID, "books")
        XCTAssertEqual(router.path(for: "books").map(\.entityID), [entityID])
    }

    @MainActor
    func testInitialImageEntityConfiguresTheNativeImageViewerRoute() throws {
        let entityID = UUID()
        let router = try XCTUnwrap(
            PrismediaUITestBootstrap.router(
                arguments: ["-prismedia-ui-testing"],
                environment: [
                    "PRISMEDIA_UI_TEST_ENTITY_ID": entityID.uuidString,
                    "PRISMEDIA_UI_TEST_ENTITY_KIND": "image",
                ]
            )
        )

        XCTAssertEqual(router.navigation.modeID, ModeCatalog.images.id)
        XCTAssertEqual(router.navigation.destinationID, "images")
        XCTAssertEqual(router.path(for: "images").map(\.entityID), [entityID])
    }

    @MainActor
    func testInitialSeriesEntityConfiguresTheTelevisionSeriesRoute() throws {
        let entityID = UUID()
        let router = try XCTUnwrap(
            PrismediaUITestBootstrap.router(
                arguments: ["-prismedia-ui-testing"],
                environment: [
                    "PRISMEDIA_UI_TEST_ENTITY_ID": entityID.uuidString,
                    "PRISMEDIA_UI_TEST_ENTITY_KIND": "video-series",
                ]
            )
        )

        XCTAssertEqual(router.navigation.modeID, ModeCatalog.video.id)
        XCTAssertEqual(router.navigation.destinationID, "series")
        XCTAssertEqual(router.path(for: "series").map(\.entityID), [entityID])
    }

    @MainActor
    func testInitialModeAndDestinationConfigureAFeatureSmokeRoute() throws {
        let router = try XCTUnwrap(
            PrismediaUITestBootstrap.router(
                arguments: ["-prismedia-ui-testing"],
                environment: [
                    "PRISMEDIA_UI_TEST_MODE_ID": "manage",
                    "PRISMEDIA_UI_TEST_DESTINATION_ID": "request",
                ]
            )
        )

        XCTAssertEqual(router.navigation.modeID, "manage")
        XCTAssertEqual(router.navigation.destinationID, "request")
    }

    func testVideoAutostartRequiresUITestingAndTheExplicitFlag() {
        let environment = ["PRISMEDIA_UI_TEST_START_VIDEO": "1"]

        XCTAssertFalse(
            PrismediaUITestBootstrap.startsVideoAutomatically(
                arguments: [],
                environment: environment
            )
        )
        XCTAssertTrue(
            PrismediaUITestBootstrap.startsVideoAutomatically(
                arguments: ["-prismedia-ui-testing"],
                environment: environment
            )
        )
    }

    func testVideoFullscreenStartRequiresUITestingAndTheExplicitFlag() {
        let environment = ["PRISMEDIA_UI_TEST_START_FULLSCREEN": "1"]

        XCTAssertFalse(
            PrismediaUITestBootstrap.startsVideoInFullscreen(
                arguments: [],
                environment: environment
            )
        )
        XCTAssertTrue(
            PrismediaUITestBootstrap.startsVideoInFullscreen(
                arguments: ["-prismedia-ui-testing"],
                environment: environment
            )
        )
    }

    func testEntityDetailBottomStartRequiresUITestingAndTheExplicitFlag() {
        let environment = ["PRISMEDIA_UI_TEST_DETAIL_SCROLL_BOTTOM": "1"]

        XCTAssertFalse(
            PrismediaUITestBootstrap.startsEntityDetailAtBottom(
                arguments: [],
                environment: environment
            )
        )
        XCTAssertTrue(
            PrismediaUITestBootstrap.startsEntityDetailAtBottom(
                arguments: ["-prismedia-ui-testing"],
                environment: environment
            )
        )
    }

    func testDashboardHeroAutoAdvanceDisableRequiresUITestingAndTheExplicitFlag() {
        let environment = ["PRISMEDIA_UI_TEST_DISABLE_HERO_AUTO_ADVANCE": "1"]

        XCTAssertFalse(
            PrismediaUITestBootstrap.disablesDashboardHeroAutoAdvance(
                arguments: [],
                environment: environment
            )
        )
        XCTAssertTrue(
            PrismediaUITestBootstrap.disablesDashboardHeroAutoAdvance(
                arguments: ["-prismedia-ui-testing"],
                environment: environment
            )
        )
    }
}
