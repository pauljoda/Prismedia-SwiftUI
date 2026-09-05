import XCTest

/// Protects confirmation ownership and the signed-out transition from the pushed Account page.
final class PrismediaTVAccountSettingsUITests: XCTestCase {
    @MainActor
    func testAccountSignOutCanBeCancelledThenConfirmed() {
        let app = XCUIApplication()
        app.launchArguments += ["-prismedia-ui-testing"]
        app.launchEnvironment["PRISMEDIA_UI_TEST_SESSION_SERVER"] =
            ProcessInfo.processInfo.environment["PRISMEDIA_UI_TEST_SERVER"] ?? "http://localhost:8899"
        app.launchEnvironment["PRISMEDIA_UI_TEST_SESSION_TOKEN"] = "mock-session-token"
        app.launchEnvironment["PRISMEDIA_UI_TEST_TV_TAB_ID"] = "account"
        app.launchEnvironment["PRISMEDIA_UI_TEST_TV_SETTINGS_DESTINATION"] = "account"
        app.launch()

        let signOut = app.buttons.matching(identifier: "tv.account.sign-out")
        XCTAssertTrue(signOut.firstMatch.waitForExistence(timeout: 15))
        XCUIRemote.shared.press(.down)
        XCUIRemote.shared.press(.select)

        let alert = app.alerts["Sign Out?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        guard alert.exists else { return }
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(signOut.firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(app.textFields["auth.server.field"].exists)

        XCUIRemote.shared.press(.select)
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        XCUIRemote.shared.press(.right)
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(app.textFields["auth.server.field"].waitForExistence(timeout: 10))
        XCTAssertFalse(signOut.firstMatch.exists)
    }

}
