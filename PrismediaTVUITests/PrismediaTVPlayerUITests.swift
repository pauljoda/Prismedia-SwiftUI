import XCTest

final class PrismediaTVPlayerUITests: XCTestCase {
    @MainActor
    func testCompatibilityPlayerRemoteInteractionFlow() async throws {
        let app = XCUIApplication()
        app.launchArguments += ["-prismedia-reset-session", "-prismedia-ui-testing"]
        app.launchEnvironment["PRISMEDIA_UI_TEST_SESSION_SERVER"] =
            ProcessInfo.processInfo.environment["PRISMEDIA_UI_TEST_SERVER"]
            ?? "http://localhost:8899"
        app.launchEnvironment["PRISMEDIA_UI_TEST_SESSION_TOKEN"] = "mock-session-token"
        app.launchEnvironment["PRISMEDIA_UI_TEST_DISABLE_HERO_AUTO_ADVANCE"] = "1"
        app.launchEnvironment["PRISMEDIA_UI_TEST_ENTITY_ID"] =
            "33333333-3333-3333-3333-333333333333"
        app.launchEnvironment["PRISMEDIA_UI_TEST_ENTITY_KIND"] = "movie"
        app.launchEnvironment["PRISMEDIA_UI_TEST_START_VIDEO"] = "1"
        app.launchEnvironment["PRISMEDIA_UI_TEST_START_FULLSCREEN"] = "1"
        app.launchEnvironment["PRISMEDIA_UI_TEST_VIDEO_ENGINE"] = "vlc"
        app.launchEnvironment["PRISMEDIA_UI_TEST_VIDEO_RESUME_SECONDS"] = "30"
        app.launchEnvironment["PRISMEDIA_UI_TEST_VIDEO_CONTROLS_TIMEOUT"] = "4"
        app.launchEnvironment["PRISMEDIA_UI_TEST_VIDEO_SCAN_SETTLE_SECONDS"] = "5"
        app.launch()

        let surface = element("video-player.compatibility-surface", in: app)
        XCTAssertTrue(surface.waitForExistence(timeout: 20))

        let audio = app.buttons["Audio Tracks"]
        let subtitles = app.buttons["Subtitles"]
        let speed = app.buttons["Playback Speed"]
        let menuButtons = [audio, subtitles, speed]
        XCTAssertTrue(waitForDisappearance(of: audio, timeout: 5))

        XCUIRemote.shared.press(.right)
        try await Task.sleep(for: .milliseconds(300))
        XCTAssertFalse(audio.exists, "A hidden-player skip must not reveal playback chrome.")

        XCUIRemote.shared.press(.up)
        XCTAssertTrue(audio.waitForExistence(timeout: 3))
        XCTAssertTrue(waitForFocus(on: surface))

        XCUIRemote.shared.press(.up)
        XCTAssertTrue(waitForAnyFocus(in: menuButtons))
        XCTAssertTrue(waitForFocus(on: audio))
        XCUIRemote.shared.press(.right)
        XCTAssertTrue(waitForFocus(on: subtitles))
        XCUIRemote.shared.press(.right)
        XCTAssertTrue(waitForFocus(on: speed))

        try await Task.sleep(for: .seconds(4.5))
        XCTAssertTrue(
            menuButtons.contains(where: \.hasFocus),
            "Focused playback menus must suspend chrome auto-dismissal."
        )

        XCUIRemote.shared.press(.left)
        XCTAssertTrue(waitForFocus(on: subtitles))
        try await Task.sleep(for: .seconds(4.5))
        XCTAssertTrue(
            menuButtons.contains(where: \.hasFocus),
            "Navigating the playback menus must keep the chrome visible."
        )

        XCUIRemote.shared.press(.down)
        XCTAssertTrue(waitForFocus(on: surface))

        XCUIRemote.shared.press(.select)
        XCUIRemote.shared.press(.right)
        assertScanIndicator(in: app, label: "Fast Forward", value: "2 times")

        XCUIRemote.shared.press(.right)
        assertScanIndicator(in: app, label: "Fast Forward", value: "4 times")

        XCUIRemote.shared.press(.right)
        assertScanIndicator(in: app, label: "Fast Forward", value: "8 times")

        XCUIRemote.shared.press(.left)
        assertScanIndicator(in: app, label: "Rewind", value: "2 times")

        XCUIRemote.shared.press(.select)
        XCTAssertFalse(element("video-player.scan-indicator", in: app).exists)

        try await Task.sleep(for: .milliseconds(300))
        XCUIRemote.shared.press(.select)
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(waitForValue(on: surface, containing: "Scrubbing"))
        let positionBeforeSwipe = surface.value as? String

        XCUIRemote.shared.press(.right)
        XCTAssertTrue(waitForValueChange(on: surface, from: positionBeforeSwipe))
        XCTAssertTrue((surface.value as? String)?.contains("Scrubbing") == true)

        XCUIRemote.shared.press(.select)
        XCTAssertTrue(waitForValue(on: surface, excluding: "Scrubbing"))
    }

    @MainActor
    private func assertScanIndicator(
        in app: XCUIApplication,
        label: String,
        value: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let indicator = element("video-player.scan-indicator", in: app)
        XCTAssertTrue(indicator.waitForExistence(timeout: 3), file: file, line: line)
        XCTAssertEqual(indicator.label, label, file: file, line: line)
        XCTAssertEqual(indicator.value as? String, value, file: file, line: line)
    }

    @MainActor
    private func waitForFocus(on element: XCUIElement, timeout: TimeInterval = 3) -> Bool {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "hasFocus == true"),
            object: element
        )
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    @MainActor
    private func waitForAnyFocus(
        in elements: [XCUIElement],
        timeout: TimeInterval = 3
    ) -> Bool {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in elements.contains(where: \.hasFocus) },
            object: elements[0]
        )
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    @MainActor
    private func waitForDisappearance(
        of element: XCUIElement,
        timeout: TimeInterval
    ) -> Bool {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"),
            object: element
        )
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    @MainActor
    private func waitForValue(
        on element: XCUIElement,
        containing text: String,
        timeout: TimeInterval = 3
    ) -> Bool {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value CONTAINS %@", text),
            object: element
        )
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    @MainActor
    private func waitForValue(
        on element: XCUIElement,
        excluding text: String,
        timeout: TimeInterval = 3
    ) -> Bool {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "NOT (value CONTAINS %@)", text),
            object: element
        )
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    @MainActor
    private func waitForValueChange(
        on element: XCUIElement,
        from value: String?,
        timeout: TimeInterval = 3
    ) -> Bool {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value != %@", value ?? ""),
            object: element
        )
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    @MainActor
    private func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }
}
