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
        app.launchEnvironment["PRISMEDIA_UI_TEST_VIDEO_RESUME_SECONDS"] = "0"
        app.launchEnvironment["PRISMEDIA_UI_TEST_VIDEO_CONTROLS_TIMEOUT"] = "4"
        app.launchEnvironment["PRISMEDIA_UI_TEST_VIDEO_SCAN_SETTLE_SECONDS"] = "5"
        app.launch()

        let surface = element("video-player.compatibility-surface", in: app)
        XCTAssertTrue(surface.waitForExistence(timeout: 20))

        let audio = app.buttons["Audio Tracks"]
        let subtitles = app.buttons["Subtitles"]
        let speed = app.buttons["Playback Speed"]
        XCTAssertTrue(waitForDisappearance(of: audio, timeout: 10))

        XCUIRemote.shared.press(.right)
        try await Task.sleep(for: .milliseconds(300))
        XCTAssertFalse(audio.exists, "A hidden-player skip must not reveal playback chrome.")

        XCUIRemote.shared.press(.up)
        XCTAssertTrue(audio.waitForExistence(timeout: 3))
        XCTAssertTrue(waitForFocus(on: surface))

        XCUIRemote.shared.press(.up)
        XCUIRemote.shared.press(.select)
        let commentaryAudio = element(label: "Commentary", in: app)
        XCTAssertTrue(
            commentaryAudio.waitForExistence(timeout: 3),
            "Audio choices should open in an anchored native menu."
        )
        let audioMenuCell = app.cells.firstMatch
        XCTAssertTrue(waitForFocus(on: audioMenuCell))
        try await Task.sleep(for: .seconds(1.6))
        XCTAssertTrue(
            commentaryAudio.exists && audioMenuCell.hasFocus,
            "Live playback updates must not recreate or reset an open native menu."
        )
        XCUIRemote.shared.press(.menu)
        XCTAssertTrue(waitForDisappearance(of: commentaryAudio, timeout: 3))
        XCTAssertTrue(audio.waitForExistence(timeout: 3))

        XCUIRemote.shared.press(.right)
        XCUIRemote.shared.press(.select)
        let subtitlesOff = element(label: "Off", in: app)
        XCTAssertTrue(
            subtitlesOff.waitForExistence(timeout: 3),
            "Subtitle choices should open in an anchored native menu."
        )
        XCUIRemote.shared.press(.menu)
        XCTAssertTrue(waitForDisappearance(of: subtitlesOff, timeout: 3))

        XCUIRemote.shared.press(.right)
        XCUIRemote.shared.press(.select)
        let doubleSpeed = element(label: "2×", in: app)
        XCTAssertTrue(
            doubleSpeed.waitForExistence(timeout: 3),
            "Playback speed choices should open in an anchored native menu."
        )
        XCUIRemote.shared.press(.menu)
        XCTAssertTrue(waitForDisappearance(of: doubleSpeed, timeout: 3))

        try await Task.sleep(for: .seconds(4.5))
        XCTAssertTrue(
            audio.exists && subtitles.exists && speed.exists,
            "Focused playback menus must suspend chrome auto-dismissal."
        )

        XCUIRemote.shared.press(.left)
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(
            subtitlesOff.waitForExistence(timeout: 3),
            "Left/right remote navigation should move between native playback menus."
        )
        XCUIRemote.shared.press(.menu)
        XCTAssertTrue(waitForDisappearance(of: subtitlesOff, timeout: 3))
        try await Task.sleep(for: .seconds(4.5))
        XCTAssertTrue(
            audio.exists,
            "Navigating the playback menus must keep the chrome visible."
        )

        XCUIRemote.shared.press(.down)
        XCTAssertTrue(waitForFocus(on: surface))

        XCUIRemote.shared.press(.playPause)
        try await Task.sleep(for: .milliseconds(300))
        XCUIRemote.shared.press(.playPause)
        XCTAssertTrue(
            waitForDisappearance(of: audio, timeout: 7),
            "Resuming playback should re-arm chrome auto-dismissal."
        )
        XCTAssertTrue(surface.exists)

        XCUIRemote.shared.press(.up)
        XCTAssertTrue(audio.waitForExistence(timeout: 3))
        XCUIRemote.shared.press(.menu)
        XCTAssertTrue(
            waitForDisappearance(of: audio, timeout: 3),
            "Back should hide visible playback chrome before dismissing playback."
        )
        XCTAssertTrue(surface.exists, "Hiding playback chrome must not exit the player.")

        XCUIRemote.shared.press(.up)
        XCTAssertTrue(audio.waitForExistence(timeout: 3))
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

    @MainActor
    private func element(label: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@", label))
            .firstMatch
    }
}
