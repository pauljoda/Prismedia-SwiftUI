import XCTest

/// TEMPORARY diagnostic for the "fullscreen opens then instantly dismisses" bug.
/// Delete once the fullscreen presentation regression is resolved.
final class TempFullscreenRepro: XCTestCase {
    @MainActor
    func testTapResumeKeepsFullscreenPlayer() throws {
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        let app = XCUIApplication()
        app.launchArguments += ["-prismedia-reset-session", "-prismedia-ui-testing"]
        app.launchEnvironment["PRISMEDIA_UI_TEST_SESSION_SERVER"] = "http://localhost:8899"
        app.launchEnvironment["PRISMEDIA_UI_TEST_SESSION_TOKEN"] = "mock-session-token"
        app.launchEnvironment["PRISMEDIA_UI_TEST_DISABLE_HERO_AUTO_ADVANCE"] = "1"
        app.launchEnvironment["PRISMEDIA_UI_TEST_ENTITY_ID"] =
            "11111111-1111-1111-1111-111111111111"
        app.launchEnvironment["PRISMEDIA_UI_TEST_ENTITY_KIND"] = "video"
        app.launch()

        XCTAssertTrue(
            app.descendants(matching: .any)["entity-detail.content"]
                .waitForExistence(timeout: 30),
            "detail page never appeared"
        )

        let resume = app.descendants(matching: .any)["entity-detail.action.resume"]
            .firstMatch
        XCTAssertTrue(resume.waitForExistence(timeout: 15), "no Resume action")
        resume.tap()

        let player = app.descendants(matching: .any)["video-player.surface"]
        XCTAssertTrue(
            player.waitForExistence(timeout: 15),
            "fullscreen player never appeared at all"
        )

        // The regression: it appears, then tears itself down within a frame or two.
        Thread.sleep(forTimeInterval: 6)
        attachScreenshot(name: "after-settle")
        XCTAssertTrue(
            player.exists,
            "REPRO: fullscreen player appeared then dismissed itself"
        )

        // Player must become interactive (not stuck on a preparation spinner).
        let stuck = NSPredicate(
            format: "label BEGINSWITH 'Preparing video' OR label BEGINSWITH 'Starting playback'"
        )
        let spinnerGone = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "count == 0"),
            object: app.staticTexts.matching(stuck)
        )
        let result = XCTWaiter.wait(for: [spinnerGone], timeout: 15)
        attachScreenshot(name: "interactive-check")
        XCTAssertEqual(result, .completed, "player stayed non-interactive (stuck preparing)")
    }

    @MainActor
    private func attachScreenshot(name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
