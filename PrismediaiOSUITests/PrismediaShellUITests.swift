import XCTest

/// Broad cross-boundary smoke tests backed by Scripts/mock-server.py on localhost:8899.
final class PrismediaShellUITests: XCTestCase {
    @MainActor
    func testAudiobookResumesTheCorrectPartInTheNativePlayer() throws {
        let app = signedInApplication(
            initialEntityID: "abababab-abab-abab-abab-abababababab",
            kind: "book"
        )
        XCTAssertTrue(element("entity-detail.content", in: app).waitForExistence(timeout: 10))

        let listen = element("media-progress.resume", in: app)
        XCTAssertTrue(listen.waitForExistence(timeout: 10))
        XCTAssertTrue(waitForHittable(listen))
        listen.tap()

        let miniPlayer = app.buttons.matching(
            NSPredicate(
                format: "identifier == %@ AND label BEGINSWITH %@",
                "music.mini-player",
                "Now Playing"
            )
        ).firstMatch
        XCTAssertTrue(miniPlayer.waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Part Two"].waitForExistence(timeout: 5))

        miniPlayer.tap()
        let nowPlaying = element("music.now-playing", in: app)
        XCTAssertTrue(nowPlaying.waitForExistence(timeout: 10))

        let closePlayer = element("music.close-player", in: app)
        XCTAssertTrue(closePlayer.waitForExistence(timeout: 5))
        closePlayer.tap()

        let nowPlayingDismissed = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"),
            object: nowPlaying
        )
        XCTAssertEqual(XCTWaiter.wait(for: [nowPlayingDismissed], timeout: 5), .completed)
        XCTAssertTrue(miniPlayer.exists)
    }

    @MainActor
    func testNativePlaybackSwitchesAudioAndStyledSubtitles() throws {
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        let app = signedInApplication(
            initialEntityID: "11111111-1111-1111-1111-111111111111",
            kind: "video",
            startVideo: true,
            startFullscreen: true
        )
        let player = element("video-player.surface", in: app)
        XCTAssertTrue(player.waitForExistence(timeout: 20))
        XCTAssertTrue(waitForLandscape(in: app))
        revealPlaybackChrome(in: app)
        let pause = app.buttons["Pause"].firstMatch
        if pause.waitForExistence(timeout: 3), waitForHittable(pause) {
            pause.tap()
        }

        openPlaybackOptions(in: app)
        let subtitles = app.buttons["Subtitles"]
        XCTAssertTrue(subtitles.waitForExistence(timeout: 5))
        subtitles.tap()
        let englishMarkup = app.buttons["English WebVTT Markup"]
        XCTAssertTrue(englishMarkup.waitForExistence(timeout: 5))
        englishMarkup.tap()

        let renderedMarkup = app.staticTexts["This is italic, bold, and underlined."].firstMatch
        XCTAssertTrue(renderedMarkup.waitForExistence(timeout: 5))
        XCTAssertFalse(renderedMarkup.label.contains("<i>"))

        openPlaybackOptions(in: app)
        app.buttons["Subtitles"].tap()
        let englishStyled = app.buttons["English Styled"]
        XCTAssertTrue(englishStyled.waitForExistence(timeout: 5))
        englishStyled.tap()

        openPlaybackOptions(in: app)
        let audio = app.buttons["Audio"]
        XCTAssertTrue(audio.waitForExistence(timeout: 5))
        audio.tap()
        let commentary = app.buttons["Commentary"]
        XCTAssertTrue(commentary.waitForExistence(timeout: 5))
        commentary.tap()
        XCTAssertTrue(player.waitForExistence(timeout: 10))

        let exitFullscreen = app.buttons["Exit Full Screen"].firstMatch
        if !exitFullscreen.isHittable {
            revealPlaybackChrome(in: app)
        }
        XCTAssertTrue(exitFullscreen.waitForExistence(timeout: 5))
        exitFullscreen.tap()
        XCTAssertTrue(waitForPortrait(in: app))
    }

    @MainActor
    func testRapidEpisodeFullscreenDismissRestoresPortraitAndSeason() throws {
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        let app = signedInApplication(
            initialEntityID: "10101010-1010-1010-1010-101010101010",
            kind: "video-season"
        )
        XCTAssertTrue(element("entity-detail.content", in: app).waitForExistence(timeout: 10))

        let episode = app.buttons.matching(
            identifier: "entity-detail.child.12010100-1212-1212-1212-000000000001"
        ).matching(
            NSPredicate(format: "label BEGINSWITH %@", "E1, Mock Episode One")
        ).firstMatch
        for _ in 0..<4 where !episode.exists {
            app.swipeUp()
        }
        XCTAssertTrue(episode.waitForExistence(timeout: 5))
        episode.tap()

        let player = element("video-player.surface", in: app)
        XCTAssertTrue(player.waitForExistence(timeout: 10))
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.08)).tap()

        XCTAssertTrue(waitForPortrait(in: app))
        XCTAssertTrue(element("entity-detail.content", in: app).waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Season 1"].exists)
    }

    @MainActor
    func testSignInSearchesAndOpensAnEntity() throws {
        let app = launchedApplication()
        addUIInterruptionMonitor(withDescription: "Password save prompt") { alert in
            let notNow = alert.buttons["Not Now"]
            guard notNow.exists else { return false }
            notNow.tap()
            return true
        }

        XCTAssertTrue(element("auth.brand.logo", in: app).waitForExistence(timeout: 10))
        advanceToLogin(serverURL: "localhost:8899", in: app)
        submitCredentials(username: "test", password: "test1234", in: app)
        app.tap()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10))
        XCTAssertTrue(element("shell.dashboard", in: app).waitForExistence(timeout: 10))

        let browseScreen = element("shell.search", in: app)
        selectBrowse(tabBar.buttons["Browse"], screen: browseScreen, tabBar: tabBar)
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("Movie One")

        let movieResult = element(
            "shell.search.result.33333333-3333-3333-3333-333333333333",
            in: app
        )
        XCTAssertTrue(movieResult.waitForExistence(timeout: 10))
        movieResult.tap()

        XCTAssertTrue(element("entity-detail.content", in: app).waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Mock Movie One"].exists)
    }

    @MainActor
    private func signedInApplication(
        initialEntityID: String,
        kind: String,
        startVideo: Bool = false,
        startFullscreen: Bool = false
    ) -> XCUIApplication {
        let app = launchedApplication(preauthenticated: true, launch: false)
        app.launchEnvironment["PRISMEDIA_UI_TEST_DISABLE_HERO_AUTO_ADVANCE"] = "1"
        app.launchEnvironment["PRISMEDIA_UI_TEST_ENTITY_ID"] = initialEntityID
        app.launchEnvironment["PRISMEDIA_UI_TEST_ENTITY_KIND"] = kind
        if startVideo {
            app.launchEnvironment["PRISMEDIA_UI_TEST_START_VIDEO"] = "1"
        }
        if startFullscreen {
            app.launchEnvironment["PRISMEDIA_UI_TEST_START_FULLSCREEN"] = "1"
        }
        app.launch()
        return app
    }

    @MainActor
    private func launchedApplication(
        preauthenticated: Bool = false,
        launch: Bool = true
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-prismedia-reset-session", "-prismedia-ui-testing"]
        if preauthenticated {
            app.launchEnvironment["PRISMEDIA_UI_TEST_SESSION_SERVER"] =
                ProcessInfo.processInfo.environment["PRISMEDIA_UI_TEST_SERVER"]
                ?? "http://localhost:8899"
            app.launchEnvironment["PRISMEDIA_UI_TEST_SESSION_TOKEN"] = "mock-session-token"
        }
        if launch {
            app.launch()
        }
        return app
    }

    @MainActor
    private func advanceToLogin(serverURL: String, in app: XCUIApplication) {
        let serverField = app.textFields["Server URL"]
        XCTAssertTrue(serverField.waitForExistence(timeout: 10))
        replaceText(in: serverField, with: serverURL, placeholder: "prismedia.example.com")
        app.buttons["Continue"].firstMatch.tap()
        XCTAssertTrue(app.textFields["Username"].waitForExistence(timeout: 10))
    }

    @MainActor
    private func submitCredentials(username: String, password: String, in app: XCUIApplication) {
        let usernameField = app.textFields["Username"]
        XCTAssertTrue(usernameField.waitForExistence(timeout: 10))
        usernameField.tap()
        usernameField.typeText(username)
        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText(password)
        app.buttons["Sign In"].firstMatch.tap()
    }

    @MainActor
    private func openPlaybackOptions(in app: XCUIApplication) {
        let playbackOptions = app.buttons["Playback Options"]
        if !playbackOptions.isHittable {
            revealPlaybackChrome(in: app)
        }
        XCTAssertTrue(playbackOptions.waitForExistence(timeout: 5))
        XCTAssertTrue(waitForHittable(playbackOptions))
        playbackOptions.tap()
    }

    @MainActor
    private func revealPlaybackChrome(in app: XCUIApplication) {
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.72, dy: 0.5)).tap()
    }

    @MainActor
    private func waitForHittable(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "hittable == true"),
            object: element
        )
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    @MainActor
    private func waitForLandscape(in app: XCUIApplication, timeout: TimeInterval = 8) -> Bool {
        waitForGeometry(in: app, timeout: timeout) { $0.width > $0.height }
    }

    @MainActor
    private func waitForPortrait(in app: XCUIApplication, timeout: TimeInterval = 8) -> Bool {
        waitForGeometry(in: app, timeout: timeout) { $0.height > $0.width }
    }

    @MainActor
    private func waitForGeometry(
        in app: XCUIApplication,
        timeout: TimeInterval,
        matches: @escaping (CGRect) -> Bool
    ) -> Bool {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in matches(app.frame) },
            object: app
        )
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    @MainActor
    private func replaceText(
        in field: XCUIElement,
        with replacement: String,
        placeholder: String
    ) {
        let existingValue = field.value as? String ?? ""
        field.tap()
        if !existingValue.isEmpty, existingValue != placeholder {
            field.typeText(
                String(repeating: XCUIKeyboardKey.delete.rawValue, count: existingValue.count)
            )
        }
        field.typeText(replacement)
        XCTAssertEqual(field.value as? String, replacement)
    }

    @MainActor
    private func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    @MainActor
    private func selectBrowse(
        _ button: XCUIElement,
        screen: XCUIElement,
        tabBar: XCUIElement
    ) {
        if button.isHittable {
            button.tap()
        } else {
            tabBar.coordinate(withNormalizedOffset: CGVector(dx: 0.94, dy: 0.5)).tap()
        }
        if !screen.waitForExistence(timeout: 2) {
            tabBar.coordinate(withNormalizedOffset: CGVector(dx: 0.94, dy: 0.5)).tap()
        }
        XCTAssertTrue(screen.waitForExistence(timeout: 5))
    }
}
