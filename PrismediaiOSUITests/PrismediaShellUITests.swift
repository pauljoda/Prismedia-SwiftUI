import XCTest

/// End-to-end smoke test for the sign-in flow and the mode-adaptive shell.
/// Expects the mock Prismedia server (Scripts/mock-server.py) on localhost:8899.
///
/// Browse-shell accessibility contract:
/// - `shell.search` identifies the permanent Browse destination's root.
/// - `shell.search.mode.<modeID>` identifies each browse-mode control.
/// - `shell.search.result.<entityID>` identifies a media result.
/// - `shell.account` identifies the account toolbar menu.
final class PrismediaShellUITests: XCTestCase {
    @MainActor
    func testEntityDetailProgressCardUsesOnePrimaryAndCompactSecondaryActions() throws {
        let app = signedInApplication(
            initialEntityID: "88888888-8888-8888-8888-888888888888",
            kind: "book"
        )

        XCTAssertTrue(element("entity-detail.content", in: app).waitForExistence(timeout: 10))
        let progress = element("entity-detail.reading-progress", in: app)
        for _ in 0..<6 where !progress.exists {
            app.swipeUp()
        }
        XCTAssertTrue(progress.waitForExistence(timeout: 5))

        let resume = element("media-progress.resume", in: app)
        let startOver = element("media-progress.start-over", in: app)
        let completion = element("media-progress.completion", in: app)
        XCTAssertTrue(resume.waitForExistence(timeout: 5))
        XCTAssertTrue(startOver.exists)
        XCTAssertTrue(completion.exists)
        XCTAssertFalse(element("entity-detail.action.resume", in: app).exists)
        XCTAssertGreaterThan(resume.frame.width, startOver.frame.width * 2)
        XCTAssertEqual(startOver.frame.minY, completion.frame.minY, accuracy: 2)
        attachScreenshot(of: app, named: "entity-detail-native-progress-card")
    }

    @MainActor
    func testEntityDetailArtworkContinuesIntoInformationSurface() throws {
        let app = signedInApplication(
            initialEntityID: "33333333-3333-3333-3333-333333333333",
            kind: "movie"
        )

        XCTAssertTrue(element("entity-detail.content", in: app).waitForExistence(timeout: 10))
        XCTAssertTrue(
            element("entity-detail.hero-information", in: app).waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            app.navigationBars.staticTexts["Mock Movie One"].waitForExistence(timeout: 5)
        )
        attachScreenshot(of: app, named: "entity-detail-artwork-continuation")

        let moreActions = element("entity-detail.more-actions", in: app)
        XCTAssertTrue(moreActions.waitForExistence(timeout: 5))
        moreActions.tap()
        XCTAssertTrue(
            element("entity-detail.add-to-collection", in: app).waitForExistence(timeout: 5)
        )
        XCTAssertTrue(element("entity-detail.action.favorite", in: app).exists)
        XCTAssertTrue(element("entity-detail.action.organized", in: app).exists)
        attachScreenshot(of: app, named: "entity-detail-toolbar-menu")
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

        let sectionPicker = element("entity-detail.section-picker", in: app)
        for _ in 0..<6 where !sectionPicker.exists {
            app.swipeUp()
        }
        XCTAssertTrue(sectionPicker.waitForExistence(timeout: 5))
        XCTAssertTrue(element("entity-detail.panel.details", in: app).exists)
        attachScreenshot(of: app, named: "entity-detail-native-sections")
    }

    @MainActor
    func testDashboardKeepsHeroBelowTopBarAndInsideViewport() throws {
        let app = signedInApplication(modeID: "overview", destinationID: "dashboard")
        let hero = app.descendants(matching: .any)
            .matching(identifier: "dashboard.hero")
            .firstMatch

        XCTAssertTrue(hero.waitForExistence(timeout: 10))
        XCTAssertGreaterThan(
            hero.frame.minY,
            app.frame.height * 0.02,
            "The sharp featured artwork must begin below the top system header."
        )
        XCTAssertLessThan(
            hero.frame.minY,
            app.frame.height * 0.16,
            "The hero should remain adjacent to the top bar so its background extension can fill the safe area."
        )
        let heroTitle = app.staticTexts.matching(identifier: "dashboard.hero.title").firstMatch
        XCTAssertTrue(heroTitle.waitForExistence(timeout: 5))
        XCTAssertGreaterThanOrEqual(
            heroTitle.frame.minX,
            app.frame.minX,
            "The hero title must remain inside the viewport's leading edge."
        )
        XCTAssertLessThanOrEqual(
            heroTitle.frame.maxX,
            app.frame.maxX,
            "The hero title must remain inside the viewport's trailing edge."
        )
        attachScreenshot(of: app, named: "dashboard-hero-background-extension")
    }

    @MainActor
    func testManageRequestAndIdentifyRoutesLoadFromAnIsolatedSession() throws {
        let requestApp = signedInApplication(modeID: "manage", destinationID: "request")
        XCTAssertTrue(element("request.workspace", in: requestApp).waitForExistence(timeout: 10))
        XCTAssertTrue(requestApp.staticTexts["Discover Movies"].waitForExistence(timeout: 10))
        XCTAssertTrue(requestApp.staticTexts["The Movie Database"].exists)
        XCTAssertTrue(requestApp.buttons["Settings"].exists)
        attachScreenshot(of: requestApp, named: "manage-request-discovery")

        requestApp.terminate()

        let identifyApp = signedInApplication(modeID: "manage", destinationID: "identify")
        XCTAssertTrue(element("identify.root", in: identifyApp).waitForExistence(timeout: 10))
        let queue = identifyApp.staticTexts["Identify Queue"]
        XCTAssertTrue(queue.waitForExistence(timeout: 10))
        queue.tap()
        XCTAssertTrue(identifyApp.staticTexts["Arrival"].waitForExistence(timeout: 10))
        attachScreenshot(of: identifyApp, named: "manage-identify-queue")
    }

    @MainActor
    func testBookAudiobookResumesTheCorrectPartInTheNativePlayer() throws {
        let app = signedInApplication(
            initialEntityID: "abababab-abab-abab-abab-abababababab",
            kind: "book"
        )
        XCTAssertTrue(element("entity-detail.content", in: app).waitForExistence(timeout: 10))

        let listen = app.descendants(matching: .any).matching(
            identifier: "entity-detail.action.listen"
        ).firstMatch
        XCTAssertTrue(listen.waitForExistence(timeout: 10))
        XCTAssertEqual(listen.label, "Continue Listening")
        XCTAssertTrue(waitForHittable(listen))
        XCTAssertTrue(element("entity-detail.audiobook-progress", in: app).exists)
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
        XCTAssertEqual(listen.label, "Pause")
        attachScreenshot(of: app, named: "audiobook-part-two-resume")

        miniPlayer.tap()
        XCTAssertTrue(element("music.now-playing", in: app).waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["The Long Voyage"].exists || app.staticTexts["Mock Audiobook"].exists)
        attachScreenshot(of: app, named: "audiobook-native-now-playing")

        let closePlayer = element("music.close-player", in: app)
        XCTAssertTrue(closePlayer.waitForExistence(timeout: 5))
        closePlayer.tap()

        let miniPlayerDismissed = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"),
            object: miniPlayer
        )
        XCTAssertEqual(XCTWaiter.wait(for: [miniPlayerDismissed], timeout: 5), .completed)
        XCTAssertFalse(element("music.now-playing", in: app).exists)
    }

    @MainActor
    func testNowPlayingQueueSupportsAnchoringSelectionAndDismissal() throws {
        let app = signedInApplication(
            initialEntityID: "abababab-abab-abab-abab-abababababab",
            kind: "book"
        )
        XCTAssertTrue(element("entity-detail.content", in: app).waitForExistence(timeout: 10))

        let startOver = element("media-progress.start-over", in: app)
        XCTAssertTrue(startOver.waitForExistence(timeout: 10))
        XCTAssertTrue(waitForHittable(startOver))
        startOver.tap()

        let miniPlayer = app.buttons.matching(
            NSPredicate(
                format: "identifier == %@ AND label BEGINSWITH %@",
                "music.mini-player",
                "Now Playing"
            )
        ).firstMatch
        XCTAssertTrue(miniPlayer.waitForExistence(timeout: 10))
        miniPlayer.tap()

        let nowPlaying = element("music.now-playing", in: app)
        XCTAssertTrue(nowPlaying.waitForExistence(timeout: 10))
        XCTAssertTrue(element("music.shuffle", in: app).exists)
        XCTAssertTrue(element("music.repeat", in: app).exists)

        let queueButton = element("music.queue-button", in: app)
        XCTAssertTrue(queueButton.waitForExistence(timeout: 5))
        queueButton.tap()

        let queue = element("music.queue", in: app)
        let current = app.staticTexts.matching(identifier: "music.queue.current").firstMatch
        XCTAssertTrue(queue.waitForExistence(timeout: 5))
        XCTAssertTrue(current.waitForExistence(timeout: 5))
        XCTAssertLessThan(
            current.frame.minY,
            queue.frame.minY + 140,
            "The current track must remain anchored at the queue's top snap point."
        )

        let partTwo = app.buttons.matching(
            identifier: "music.queue.track.B2000000-0000-0000-0000-000000000002"
        ).firstMatch
        XCTAssertTrue(partTwo.waitForExistence(timeout: 5))

        partTwo.tap()
        XCTAssertTrue(app.staticTexts["Part Two"].waitForExistence(timeout: 5))
        XCTAssertLessThan(
            current.frame.minY,
            queue.frame.minY + 140,
            "Progressing the queue must re-anchor Currently Playing below offscreen history."
        )
        attachScreenshot(of: app, named: "music-now-playing-anchored-queue")

        queueButton.tap()
        app.swipeDown()
        XCTAssertFalse(nowPlaying.waitForExistence(timeout: 2))
    }

    @MainActor
    func testNativePlaybackMenuSwitchesAudioAndStyledSubtitles() throws {
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
        XCTAssertTrue(
            waitForLandscape(in: app),
            "Fullscreen playback must rotate the actual scene so native menus use landscape geometry."
        )
        revealPlaybackChrome(in: app)
        let pause = app.buttons["Pause"].firstMatch
        if pause.waitForExistence(timeout: 3), waitForHittable(pause) {
            pause.tap()
        }

        openPlaybackOptions(in: app)
        let subtitles = app.buttons["Subtitles"]
        XCTAssertTrue(subtitles.waitForExistence(timeout: 5))
        subtitles.tap()
        let englishStyled = app.buttons["English Styled"]
        XCTAssertTrue(
            englishStyled.waitForExistence(timeout: 5),
            "The preferred English ASS track should be exposed by the native submenu."
        )
        attachScreenshot(of: app, named: "video-native-menu-english-ass")
        let englishMarkup = app.buttons["English WebVTT Markup"]
        XCTAssertTrue(englishMarkup.waitForExistence(timeout: 5))
        englishMarkup.tap()

        let renderedMarkup = app.staticTexts["This is italic, bold, and underlined."].firstMatch
        XCTAssertTrue(renderedMarkup.waitForExistence(timeout: 5))
        XCTAssertEqual(renderedMarkup.label, "This is italic, bold, and underlined.")
        XCTAssertFalse(renderedMarkup.label.contains("<i>"))
        attachScreenshot(of: app, named: "video-webvtt-inline-styles")

        openPlaybackOptions(in: app)
        app.buttons["Subtitles"].tap()
        XCTAssertTrue(englishStyled.waitForExistence(timeout: 5))
        englishStyled.tap()
        attachScreenshot(of: app, named: "video-ass-styled-rendering")

        openPlaybackOptions(in: app)
        let audio = app.buttons["Audio"]
        XCTAssertTrue(audio.waitForExistence(timeout: 5))
        audio.tap()
        let commentary = app.buttons["Commentary"]
        XCTAssertTrue(commentary.waitForExistence(timeout: 5))
        commentary.tap()
        XCTAssertTrue(player.waitForExistence(timeout: 10))
        attachScreenshot(of: app, named: "video-commentary-replacement-installed")

        let exitFullscreen = app.buttons["Exit Full Screen"].firstMatch
        if !exitFullscreen.isHittable {
            revealPlaybackChrome(in: app)
        }
        XCTAssertTrue(exitFullscreen.waitForExistence(timeout: 5))
        exitFullscreen.tap()
        XCTAssertTrue(waitForPortrait(in: app))
    }

    @MainActor
    func testEpisodeThumbnailPlaybackDismissesBackToSeasonWithoutInlinePlayer() throws {
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        let app = signedInApplication(
            initialEntityID: "10101010-1010-1010-1010-101010101010",
            kind: "video-season"
        )
        XCTAssertTrue(element("entity-detail.content", in: app).waitForExistence(timeout: 10))

        let episode = app.buttons
            .matching(
                identifier: "entity-detail.child.12010300-1212-1212-1212-000000000003"
            )
            .matching(NSPredicate(format: "label BEGINSWITH %@", "E3"))
            .firstMatch
        for _ in 0..<6 where !episode.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(episode.waitForExistence(timeout: 5))
        XCTAssertTrue(waitForHittable(episode))
        episode.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.82)).tap()

        let player = element("video-player.surface", in: app)
        XCTAssertTrue(player.waitForExistence(timeout: 20))
        let exitFullscreen = app.buttons["Exit Full Screen"].firstMatch
        if !exitFullscreen.isHittable {
            revealPlaybackChrome(in: app)
        }
        XCTAssertTrue(exitFullscreen.waitForExistence(timeout: 5))
        exitFullscreen.tap()

        XCTAssertTrue(waitForPortrait(in: app))
        XCTAssertTrue(element("entity-detail.content", in: app).waitForExistence(timeout: 5))
        XCTAssertTrue(app.navigationBars.staticTexts["Season 1"].exists)
        XCTAssertFalse(element("video-detail.filmstrip", in: app).exists)
    }

    @MainActor
    func testVideoDetailShowsPosterUntilPlayThenReportsPreparation() throws {
        let app = signedInApplication(
            initialEntityID: "33333333-3333-3333-3333-333333333333",
            kind: "movie"
        )
        XCTAssertTrue(element("entity-detail.content", in: app).waitForExistence(timeout: 10))

        let play = element("video-detail.play", in: app)
        let preparing = element("video-detail.preparing", in: app)
        XCTAssertTrue(play.waitForExistence(timeout: 5))
        XCTAssertFalse(preparing.exists, "Opening detail must not begin playback preparation.")
        attachScreenshot(of: app, named: "video-detail-deferred-poster")

        app.terminate()
        let preparingApp = signedInApplication(
            initialEntityID: "33333333-3333-3333-3333-333333333333",
            kind: "movie",
            startVideo: true
        )
        XCTAssertTrue(
            element("video-detail.preparing", in: preparingApp).waitForExistence(timeout: 5),
            "Starting playback should immediately replace Play with preparation feedback."
        )
        attachScreenshot(of: preparingApp, named: "video-detail-preparing-after-play")
    }

    @MainActor
    func testCollectionDetailShowsEveryMixedMediaMember() throws {
        let app = signedInApplication(
            initialEntityID: "00000000-0000-0000-0000-000000000000",
            kind: "collection"
        )

        XCTAssertTrue(element("entity-detail.content", in: app).waitForExistence(timeout: 10))
        let movie = element(
            "entity-detail.child.33333333-3333-3333-3333-333333333333",
            in: app
        )
        let book = element(
            "entity-detail.child.88888888-8888-8888-8888-888888888888",
            in: app
        )
        let group = element("entity-detail.children.collection", in: app)

        XCTAssertTrue(movie.waitForExistence(timeout: 5))
        XCTAssertTrue(book.exists, "Book members must not be filtered out of a collection.")
        XCTAssertTrue(group.exists)
        XCTAssertEqual(
            group.value as? String,
            "3",
            "The shared collection surface must retain the offscreen audio member."
        )
        attachScreenshot(of: app, named: "collection-detail-mixed-media-members")
    }

    @MainActor
    func testImageViewerDirectLaunchRendersEveryMixedMediaLeaf() throws {
        let fixtures = [
            (
                id: "99999999-9999-9999-9999-999999999999",
                title: "still",
                mediaIdentifier: "image-viewer.media.still"
            ),
            (
                id: "a1000000-0000-0000-0000-000000000001",
                title: "animated-gif",
                mediaIdentifier: "image-viewer.media.animated-image"
            ),
            (
                id: "a2000000-0000-0000-0000-000000000002",
                title: "mp4-image",
                mediaIdentifier: "image-viewer.media.video"
            ),
            (
                id: "a3000000-0000-0000-0000-000000000003",
                title: "webm-with-mp4-preview",
                mediaIdentifier: "image-viewer.media.video"
            ),
        ]

        for fixture in fixtures {
            let app = signedInApplication(initialEntityID: fixture.id, kind: "image")
            let renderedMedia = element(fixture.mediaIdentifier, in: app)

            XCTAssertTrue(
                renderedMedia.waitForExistence(timeout: 15),
                "Direct launch must render the actual \(fixture.title) media leaf, not only the viewer container."
            )
            XCTAssertGreaterThanOrEqual(
                renderedMedia.frame.minX,
                app.frame.minX - 1,
                "Fullscreen \(fixture.title) media must stay inside the leading viewport edge."
            )
            XCTAssertLessThanOrEqual(
                renderedMedia.frame.maxX,
                app.frame.maxX + 1,
                "Fullscreen \(fixture.title) media must stay inside the trailing viewport edge."
            )
            XCTAssertGreaterThanOrEqual(
                renderedMedia.frame.minY,
                app.frame.minY - 1,
                "Fullscreen \(fixture.title) media must stay inside the top viewport edge."
            )
            XCTAssertLessThanOrEqual(
                renderedMedia.frame.maxY,
                app.frame.maxY + 1,
                "Fullscreen \(fixture.title) media must stay inside the bottom viewport edge."
            )
            attachScreenshot(of: app, named: "image-viewer-\(fixture.title)")

            if fixture.title == "still" {
                let viewer = element("image-viewer", in: app)
                viewer.swipeDown()
                XCTAssertFalse(
                    viewer.waitForExistence(timeout: 3),
                    "A downward swipe must dismiss the immersive image viewer."
                )
            }

            app.terminate()
        }
    }

    @MainActor
    func testGalleryFeedOpensPagedViewerAndRoutesToImageDetails() throws {
        let app = signedInApplication(
            initialEntityID: "66666666-6666-6666-6666-666666666666",
            kind: "gallery"
        )

        XCTAssertTrue(element("entity-detail.content", in: app).waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["Mock Gallery"].exists)
        let displayMenu = app.buttons["Display options"]
        XCTAssertTrue(displayMenu.waitForExistence(timeout: 5))
        displayMenu.tap()
        let gridOption = app.buttons["Grid"]
        XCTAssertTrue(gridOption.waitForExistence(timeout: 5))
        gridOption.tap()

        XCTAssertTrue(
            element(
                "entity.thumbnail.99999999-9999-9999-9999-999999999999",
                in: app
            ).waitForExistence(timeout: 10),
            "A gallery with an image count must render its thumbnail grid."
        )
        attachScreenshot(of: app, named: "gallery-image-thumbnails")

        displayMenu.tap()
        let feedOption = app.buttons["Feed"]
        XCTAssertTrue(feedOption.waitForExistence(timeout: 5))
        feedOption.tap()

        let stillFeedItem = element(
            "entity.feed.media.99999999-9999-9999-9999-999999999999",
            in: app
        )
        XCTAssertTrue(stillFeedItem.waitForExistence(timeout: 10))
        XCTAssertTrue(
            waitForValue("Still image loaded", on: stillFeedItem, timeout: 10),
            "The feed must render authenticated still source bytes instead of the gradient fallback."
        )
        let stillFrame = stillFeedItem.frame
        XCTAssertEqual(
            stillFrame.minX,
            app.frame.minX + 8,
            accuracy: 1,
            "A feed row must keep only the compact leading gutter."
        )
        XCTAssertEqual(
            stillFrame.maxX,
            app.frame.maxX - 8,
            accuracy: 1,
            "A feed row must keep only the compact trailing gutter."
        )
        XCTAssertEqual(
            stillFrame.width / stillFrame.height,
            2.0 / 3.0,
            accuracy: 0.02,
            "A feed row must use the decoded source image's exact aspect ratio."
        )
        attachScreenshot(of: app, named: "gallery-image-feed-still")

        let videoFeedItem = element(
            "entity.feed.media.A2000000-0000-0000-0000-000000000002",
            in: app
        )
        app.swipeUp()
        XCTAssertTrue(videoFeedItem.waitForExistence(timeout: 10))
        XCTAssertFalse(
            app.buttons["Pause looping image"].exists,
            "Feed media must not expose playback chrome."
        )
        attachScreenshot(of: app, named: "gallery-image-feed")
        videoFeedItem.tap()

        let viewer = element("image-viewer", in: app)
        XCTAssertTrue(viewer.waitForExistence(timeout: 10))
        XCTAssertTrue(waitForValue("3 of 4", on: viewer))
        let detailsButton = app.buttons["Show Details"]
        if !waitForHittable(detailsButton, timeout: 1) {
            viewer.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
        XCTAssertTrue(waitForHittable(detailsButton))
        XCTAssertTrue(
            waitForNotHittable(detailsButton),
            "Viewer chrome must dismiss while media remains visible."
        )

        let detailsPosition = "2 of 4"
        viewer.swipeRight()
        XCTAssertTrue(waitForValue(detailsPosition, on: viewer))
        XCTAssertFalse(
            detailsButton.isHittable,
            "Changing pages must preserve hidden viewer chrome."
        )
        attachScreenshot(of: app, named: "gallery-image-viewer-paged")

        viewer.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(waitForHittable(detailsButton))
        detailsButton.tap()

        XCTAssertTrue(element("entity-detail.content", in: app).waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Mock Animated GIF"].exists)
        attachScreenshot(of: app, named: "gallery-image-metadata-detail")

        let nativeBackButton = app.buttons["BackButton"]
        XCTAssertTrue(nativeBackButton.waitForExistence(timeout: 5))
        nativeBackButton.tap()

        XCTAssertTrue(viewer.waitForExistence(timeout: 10))
        XCTAssertTrue(
            waitForValue(detailsPosition, on: viewer, timeout: 10),
            "Returning from details must restore the image that opened those details."
        )
    }

    @MainActor
    func testImageFeedUsesCompactGutters() throws {
        let app = signedInApplication(modeID: "images", destinationID: "images")

        XCTAssertTrue(element("entity.grid", in: app).waitForExistence(timeout: 10))
        let displayMenu = app.buttons["Display options"]
        XCTAssertTrue(displayMenu.waitForExistence(timeout: 5))
        displayMenu.tap()
        let feedOption = app.buttons["Feed"]
        XCTAssertTrue(feedOption.waitForExistence(timeout: 5))
        feedOption.tap()

        let firstItem = element(
            "entity.feed.media.A3000000-0000-0000-0000-000000000003",
            in: app
        )
        let secondItem = element(
            "entity.feed.media.A2000000-0000-0000-0000-000000000002",
            in: app
        )
        XCTAssertTrue(firstItem.waitForExistence(timeout: 10))
        XCTAssertTrue(secondItem.waitForExistence(timeout: 10))
        XCTAssertTrue(
            waitForValue("Video ready", on: secondItem, timeout: 10),
            "The next video row must be ready before it becomes the active playback row."
        )

        let firstFrame = firstItem.frame
        let secondFrame = secondItem.frame
        XCTAssertEqual(firstFrame.minX, app.frame.minX + 8, accuracy: 1)
        XCTAssertEqual(firstFrame.maxX, app.frame.maxX - 8, accuracy: 1)
        XCTAssertEqual(secondFrame.minX, app.frame.minX + 8, accuracy: 1)
        XCTAssertEqual(secondFrame.maxX, app.frame.maxX - 8, accuracy: 1)
        XCTAssertEqual(firstFrame.width / firstFrame.height, 16.0 / 9.0, accuracy: 0.02)
        XCTAssertEqual(secondFrame.width / secondFrame.height, 16.0 / 9.0, accuracy: 0.02)
        XCTAssertEqual(
            secondFrame.minY,
            firstFrame.maxY + 8,
            accuracy: 1,
            "Consecutive feed media must use the compact spacing token."
        )
        attachScreenshot(of: app, named: "image-library-feed-compact-gutters")
    }

    @MainActor
    func testImageGridPullToRefreshReshufflesRandomOrder() throws {
        let app = signedInApplication(modeID: "images", destinationID: "images")
        let grid = element("entity.grid", in: app)
        XCTAssertTrue(grid.waitForExistence(timeout: 10))

        let sortMenu = app.buttons["Sort"]
        XCTAssertTrue(sortMenu.waitForExistence(timeout: 5))
        sortMenu.tap()
        let randomSort = app.buttons["Random"]
        XCTAssertTrue(randomSort.waitForExistence(timeout: 5))
        randomSort.tap()

        let imageIDs = [
            "99999999-9999-9999-9999-999999999999",
            "A1000000-0000-0000-0000-000000000001",
            "A2000000-0000-0000-0000-000000000002",
            "A3000000-0000-0000-0000-000000000003",
        ]
        XCTAssertTrue(
            imageIDs.allSatisfy {
                element("entity.thumbnail.\($0)", in: app).waitForExistence(timeout: 10)
            }
        )
        let initialOrder = imageGridOrder(imageIDs, in: app)
        XCTAssertEqual(initialOrder.count, imageIDs.count)

        var refreshedOrder = initialOrder
        for _ in 0..<3 where refreshedOrder == initialOrder {
            grid.swipeDown()
            let expectation = XCTNSPredicateExpectation(
                predicate: NSPredicate { _, _ in
                    let candidate = self.imageGridOrder(imageIDs, in: app)
                    guard candidate.count == imageIDs.count, candidate != initialOrder else {
                        return false
                    }
                    refreshedOrder = candidate
                    return true
                },
                object: app
            )
            _ = XCTWaiter.wait(for: [expectation], timeout: 3)
        }

        XCTAssertNotEqual(
            refreshedOrder,
            initialOrder,
            "Pull to refresh in Random order must visibly reshuffle the first page."
        )
        attachScreenshot(of: app, named: "image-grid-pull-to-refresh-reshuffled")
    }

    @MainActor
    func testMovieGridScrollsBeyondTheFirstViewport() throws {
        let app = signedInApplication()
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10))
        let browseScreen = element("shell.search", in: app)
        selectBrowse(tabBar.buttons["Browse"], screen: browseScreen, tabBar: tabBar)

        let videoMode = element("shell.search.mode.video", in: app)
        XCTAssertTrue(videoMode.waitForExistence(timeout: 5))
        videoMode.tap()
        let moviesTab = tabBar.buttons["Movies"]
        XCTAssertTrue(moviesTab.waitForExistence(timeout: 5))
        moviesTab.tap()
        XCTAssertTrue(moviesTab.isSelected)
        XCTAssertTrue(element("entity.grid", in: app).waitForExistence(timeout: 10))

        let laterMovie = element(
            "entity.thumbnail.90000000-0000-0000-0000-000000000010",
            in: app
        )
        for _ in 0..<8 where !laterMovie.isHittable {
            app.swipeUp()
        }

        XCTAssertTrue(
            laterMovie.waitForExistence(timeout: 5),
            "The shared entity grid must expose rows beyond its first viewport."
        )
        XCTAssertTrue(laterMovie.isHittable)
        attachScreenshot(of: app, named: "movie-grid-scrolled-beyond-first-viewport")
    }

    @MainActor
    func testRatingMutationRefreshesRetainedMovieGridThumbnail() async throws {
        let app = signedInApplication()
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10))
        let browseScreen = element("shell.search", in: app)
        selectBrowse(tabBar.buttons["Browse"], screen: browseScreen, tabBar: tabBar)

        let videoMode = element("shell.search.mode.video", in: app)
        XCTAssertTrue(videoMode.waitForExistence(timeout: 5))
        videoMode.tap()
        let moviesTab = tabBar.buttons["Movies"]
        XCTAssertTrue(moviesTab.waitForExistence(timeout: 5))
        moviesTab.tap()
        XCTAssertTrue(moviesTab.isSelected)

        let movie = element(
            "entity.thumbnail.33333333-3333-3333-3333-333333333333",
            in: app
        )
        XCTAssertTrue(movie.waitForExistence(timeout: 10))
        XCTAssertFalse(movie.label.contains("5 star rating"))
        movie.tap()

        XCTAssertTrue(element("entity-detail.content", in: app).waitForExistence(timeout: 10))
        let fiveStars = element("entity-detail.rating.5", in: app)
        XCTAssertTrue(fiveStars.waitForExistence(timeout: 5))
        fiveStars.tap()
        let detailRatingExpectation = expectation(
            for: NSPredicate(format: "value == %@", "Selected"),
            evaluatedWith: fiveStars
        )
        await fulfillment(of: [detailRatingExpectation], timeout: 10)
        attachScreenshot(of: app, named: "movie-detail-after-rating")

        let back = app.buttons["BackButton"]
        XCTAssertTrue(back.waitForExistence(timeout: 5))
        back.tap()
        XCTAssertTrue(movie.waitForExistence(timeout: 10))
        let retainedGridExpectation = expectation(
            for: NSPredicate(format: "label CONTAINS %@", "5 star rating"),
            evaluatedWith: movie
        )
        await fulfillment(of: [retainedGridExpectation], timeout: 10)
        attachScreenshot(of: app, named: "movie-grid-rating-after-detail-mutation")
    }

    @MainActor
    func testEntityDetailSkeletonAndMutationPreserveRelationships() throws {
        let app = signedInApplication()
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10))
        let browseScreen = element("shell.search", in: app)
        selectBrowse(tabBar.buttons["Browse"], screen: browseScreen, tabBar: tabBar)
        search("Mock Movie One", in: app)

        let movieResult = element(
            "shell.search.result.33333333-3333-3333-3333-333333333333",
            in: app
        )
        XCTAssertTrue(movieResult.waitForExistence(timeout: 10))
        movieResult.tap()

        let loading = element("entity-detail.loading", in: app)
        XCTAssertTrue(loading.waitForExistence(timeout: 2))
        XCTAssertFalse(loading.descendants(matching: .button).firstMatch.exists)
        attachScreenshot(of: app, named: "entity-detail-skeleton")

        XCTAssertTrue(element("entity-detail.content", in: app).waitForExistence(timeout: 10))
        let moreActions = element("entity-detail.more-actions", in: app)
        XCTAssertTrue(moreActions.waitForExistence(timeout: 5))
        moreActions.tap()
        let favorite = element("entity-detail.action.favorite", in: app)
        XCTAssertTrue(favorite.waitForExistence(timeout: 5))
        favorite.tap()
        XCTAssertTrue(element("entity-detail.content", in: app).waitForExistence(timeout: 5))

        for _ in 0..<5 where !app.staticTexts["Mock Person"].exists {
            app.swipeUp()
        }
        XCTAssertTrue(
            app.staticTexts["Mock Person"].waitForExistence(timeout: 5),
            "Refreshing after a mutation must keep the full relationship document visible."
        )
        attachScreenshot(of: app, named: "entity-detail-after-favorite-refresh")
    }

    @MainActor
    func testResumeUsesASeparatePrimaryActionRow() throws {
        let app = signedInApplication()
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10))
        let browseScreen = element("shell.search", in: app)
        selectBrowse(tabBar.buttons["Browse"], screen: browseScreen, tabBar: tabBar)
        search("Mock Book", in: app)

        let bookResult = element(
            "shell.search.result.88888888-8888-8888-8888-888888888888",
            in: app
        )
        XCTAssertTrue(bookResult.waitForExistence(timeout: 10))
        bookResult.tap()
        XCTAssertTrue(element("entity-detail.content", in: app).waitForExistence(timeout: 10))

        let resume = element("media-progress.resume", in: app)
        let moreActions = element("entity-detail.more-actions", in: app)
        XCTAssertTrue(resume.waitForExistence(timeout: 5))
        XCTAssertTrue(moreActions.waitForExistence(timeout: 5))
        XCTAssertGreaterThan(resume.frame.width, moreActions.frame.width * 2)
        XCTAssertLessThan(moreActions.frame.maxY, resume.frame.minY)
        XCTAssertFalse(element("entity-detail.modification-actions", in: app).exists)
        moreActions.tap()
        XCTAssertTrue(element("entity-detail.action.favorite", in: app).waitForExistence(timeout: 5))
        attachScreenshot(of: app, named: "entity-detail-primary-resume-row")
    }

    @MainActor
    func testComicReaderNavigatesPagesAndUsesTheSettingsMenu() throws {
        let app = signedInApplication(
            initialEntityID: "88888888-8888-8888-8888-888888888888",
            kind: "book"
        )
        XCTAssertTrue(element("entity-detail.content", in: app).waitForExistence(timeout: 10))

        let resume = element("media-progress.resume", in: app)
        XCTAssertTrue(resume.waitForExistence(timeout: 5))
        XCTAssertTrue(resume.isEnabled)
        resume.tap()

        let readerContent = element("comic-reader.content", in: app)
        XCTAssertTrue(readerContent.waitForExistence(timeout: 10))
        XCTAssertTrue(
            waitForElement(
                "comic-reader.progress",
                in: app,
                labelContaining: "1 / 3"
            )
        )
        app.buttons["Next page"].tap()
        XCTAssertTrue(
            waitForElement(
                "comic-reader.page",
                in: app,
                labelContaining: "2 / 3"
            )
        )

        let settings = app.buttons["Reader settings"]
        if !settings.exists {
            readerContent.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
        XCTAssertTrue(settings.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Webtoon"].exists)
        settings.tap()

        let twoPages = app.buttons["Two Pages"]
        XCTAssertTrue(twoPages.waitForExistence(timeout: 5))
        Thread.sleep(forTimeInterval: 3.2)
        XCTAssertTrue(settings.exists, "Reader chrome must remain visible while settings are open.")
        XCTAssertTrue(twoPages.exists, "Reader settings must remain open past the chrome timeout.")
        twoPages.tap()
        XCTAssertTrue(
            waitForElement(
                "comic-reader.page",
                in: app,
                labelContaining: "2–3 / 3"
            )
        )

        settings.tap()
        let webtoon = app.buttons["Webtoon"]
        XCTAssertTrue(webtoon.waitForExistence(timeout: 5))
        webtoon.tap()
        let previousWebtoonPage = element("comic-reader.previous", in: app)
        XCTAssertTrue(previousWebtoonPage.waitForExistence(timeout: 5))
        previousWebtoonPage.tap()
        XCTAssertTrue(
            waitForElement(
                "comic-reader.page",
                in: app,
                labelContaining: "1 / 3"
            )
        )
        let nextWebtoonPage = element("comic-reader.next", in: app)
        XCTAssertTrue(nextWebtoonPage.waitForExistence(timeout: 5))
        nextWebtoonPage.tap()
        XCTAssertTrue(
            waitForElement(
                "comic-reader.page",
                in: app,
                labelContaining: "2 / 3"
            )
        )
        attachScreenshot(of: app, named: "comic-reader-webtoon-mode")

        let closeWebtoonReader = element("comic-reader.close", in: app)
        if !closeWebtoonReader.exists {
            readerContent.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
        XCTAssertTrue(closeWebtoonReader.waitForExistence(timeout: 5))
        closeWebtoonReader.tap()
        XCTAssertTrue(element("entity-detail.content", in: app).waitForExistence(timeout: 10))
        XCTAssertTrue(element("entity-detail.reading-progress", in: app).exists)

        let resumeAgain = element("media-progress.resume", in: app)
        XCTAssertTrue(resumeAgain.waitForExistence(timeout: 10))
        resumeAgain.tap()
        XCTAssertTrue(element("comic-reader.content", in: app).waitForExistence(timeout: 10))
        XCTAssertTrue(
            waitForElement(
                "comic-reader.page",
                in: app,
                labelContaining: "2 / 3"
            ),
            "Reopening the reader should restore the latest persisted comic page."
        )
        let closeReader = app.buttons["Close reader"]
        if !closeReader.exists {
            element("comic-reader.content", in: app)
                .coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                .tap()
        }
        XCTAssertTrue(closeReader.waitForExistence(timeout: 5))
        closeReader.tap()
    }

    @MainActor
    func testEPUBReaderOpensNativeContentsAndReaderSettings() throws {
        let app = signedInApplication(
            initialEntityID: "edededed-eded-eded-eded-edededededed",
            kind: "book"
        )
        XCTAssertTrue(element("entity-detail.content", in: app).waitForExistence(timeout: 10))

        let resume = element("media-progress.resume", in: app)
        XCTAssertTrue(resume.waitForExistence(timeout: 5))
        XCTAssertTrue(waitForHittable(resume))
        XCTAssertTrue(element("entity-detail.reading-progress", in: app).exists)
        XCTAssertFalse(element("entity-detail.reading-progress.failure", in: app).exists)
        XCTAssertFalse(element("entity-detail.action.listen", in: app).exists)
        resume.tap()

        XCTAssertTrue(element("epub-reader.content", in: app).waitForExistence(timeout: 15))
        XCTAssertFalse(app.staticTexts["Couldn’t Open Reader"].exists)
        XCTAssertEqual(
            app.staticTexts.matching(NSPredicate(format: "label == %@", "Mock EPUB Novel")).count,
            1,
            "Immersive reader chrome should not reserve space for the publication title."
        )
        let navigationMenu = element("epub-reader.navigation-menu", in: app)
        XCTAssertTrue(navigationMenu.exists)

        let page = element("epub-reader.page", in: app)
        XCTAssertTrue(page.waitForExistence(timeout: 5))
        Thread.sleep(forTimeInterval: 3.2)
        XCTAssertFalse(navigationMenu.exists, "EPUB reader chrome should fade after the comic-reader delay.")
        XCTAssertEqual(page.frame.minX, app.frame.minX, accuracy: 2)
        XCTAssertEqual(page.frame.minY, app.frame.minY, accuracy: 2)
        XCTAssertEqual(page.frame.width, app.frame.width, accuracy: 2)
        XCTAssertEqual(page.frame.height, app.frame.height, accuracy: 2)
        attachScreenshot(of: app, named: "epub-reader-immersive-hidden-chrome")

        page.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(navigationMenu.waitForExistence(timeout: 5), "A page tap should reveal EPUB reader chrome.")
        let chapterProgress = app.descendants(matching: .any)
            .matching(identifier: "epub-reader.progress")
            .firstMatch
        XCTAssertTrue(chapterProgress.exists)
        XCTAssertTrue(chapterProgress.label.contains("The First Signal"))
        XCTAssertTrue(chapterProgress.label.contains("page"))

        navigationMenu.tap()
        let bookmarks = app.buttons.matching(
            NSPredicate(format: "label == %@", "Bookmarks")
        ).firstMatch
        XCTAssertTrue(bookmarks.waitForExistence(timeout: 5))
        bookmarks.tap()
        let bookmarksPanel = element("epub-reader.bookmarks", in: app)
        XCTAssertTrue(bookmarksPanel.waitForExistence(timeout: 5))
        let addBookmark = element("epub-reader.add-bookmark", in: app)
        XCTAssertTrue(addBookmark.waitForExistence(timeout: 5))
        addBookmark.tap()
        let setToggle = app.buttons.matching(identifier: "epub-reader.bookmark-toggle").firstMatch
        XCTAssertTrue(setToggle.waitForExistence(timeout: 5))
        setToggle.tap()
        bookmarksPanel.buttons["Done"].tap()
        XCTAssertTrue(bookmarksPanel.waitForNonExistence(timeout: 5))

        let quickToggle = element("epub-reader.toggle-bookmark", in: app)
        if !quickToggle.exists {
            page.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            XCTAssertTrue(quickToggle.waitForExistence(timeout: 5))
        }
        quickToggle.tap()
        let returnFromToggle = app.buttons.matching(
            NSPredicate(format: "label == %@", "Return from Toggle bookmark")
        ).firstMatch
        XCTAssertTrue(returnFromToggle.waitForExistence(timeout: 5))
        returnFromToggle.tap()
        XCTAssertTrue(
            app.buttons.matching(
                NSPredicate(format: "label == %@", "Jump to Toggle bookmark")
            ).firstMatch.waitForExistence(timeout: 5)
        )
        Thread.sleep(forTimeInterval: 0.4)
        attachScreenshot(of: app, named: "epub-reader-immersive-visible-chrome")

        Thread.sleep(forTimeInterval: 3)
        XCTAssertFalse(navigationMenu.exists)
        page.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(navigationMenu.waitForExistence(timeout: 5))
        navigationMenu.tap()
        let searchBook = app.buttons.matching(
            NSPredicate(format: "label == %@", "Search book")
        ).firstMatch
        XCTAssertTrue(searchBook.waitForExistence(timeout: 5))
        searchBook.tap()
        XCTAssertTrue(element("epub-reader.search", in: app).waitForExistence(timeout: 5))
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("lighthouse\n")
        let searchResult = app.buttons.matching(identifier: "epub-reader.search-result").firstMatch
        XCTAssertTrue(searchResult.waitForExistence(timeout: 10))
        XCTAssertTrue(searchResult.label.contains("The First Signal"))
        XCTAssertTrue(searchResult.label.localizedCaseInsensitiveContains("lighthouse"))
        tapTrailingRowWhitespace(in: searchResult)
        XCTAssertTrue(
            element("epub-reader.search", in: app).waitForNonExistence(timeout: 5),
            "The complete search-result row should navigate, including trailing whitespace."
        )

        Thread.sleep(forTimeInterval: 3)
        XCTAssertFalse(navigationMenu.exists)
        page.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(navigationMenu.waitForExistence(timeout: 5))
        navigationMenu.tap()
        let contents = app.buttons.matching(
            NSPredicate(format: "label == %@", "Table of Contents")
        ).firstMatch
        XCTAssertTrue(contents.waitForExistence(timeout: 5))
        contents.tap()
        XCTAssertTrue(element("epub-reader.contents", in: app).waitForExistence(timeout: 10))
        let firstChapter = app.staticTexts["The First Signal"]
        XCTAssertTrue(firstChapter.exists)
        let contentsRow = app.buttons.matching(identifier: "epub-reader.contents-row").firstMatch
        tapTrailingRowWhitespace(in: contentsRow)
        XCTAssertTrue(
            element("epub-reader.contents", in: app).waitForNonExistence(timeout: 5),
            "The complete table-of-contents row should navigate, including trailing whitespace."
        )

        let settings = element("epub-reader.settings-button", in: app)
        if !settings.exists {
            page.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            XCTAssertTrue(settings.waitForExistence(timeout: 5))
        }
        settings.tap()
        XCTAssertTrue(element("epub-reader.settings", in: app).waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Text Size"].exists)
        Thread.sleep(forTimeInterval: 3.2)
        XCTAssertTrue(
            element("epub-reader.settings", in: app).exists,
            "Reader chrome must not auto-dismiss an open settings surface."
        )
        attachScreenshot(of: app, named: "epub-reader-native-controls")

        app.buttons["Done"].tap()
        XCTAssertTrue(element("epub-reader.settings", in: app).waitForNonExistence(timeout: 5))
        page.swipeDown()
        XCTAssertTrue(element("entity-detail.content", in: app).waitForExistence(timeout: 10))
    }

    @MainActor
    func testPDFReaderOpensOutlineSearchAndLayoutControls() throws {
        let app = signedInApplication(
            initialEntityID: "dfdfdfdf-dfdf-dfdf-dfdf-dfdfdfdfdfdf",
            kind: "book"
        )
        XCTAssertTrue(element("entity-detail.content", in: app).waitForExistence(timeout: 10))

        let resume = element("media-progress.resume", in: app)
        XCTAssertTrue(resume.waitForExistence(timeout: 5))
        XCTAssertTrue(waitForHittable(resume))
        resume.tap()

        XCTAssertTrue(element("pdf-reader.content", in: app).waitForExistence(timeout: 15))
        app.buttons["Table of Contents"].tap()
        let secondSignal = app.staticTexts["The Second Signal"]
        XCTAssertTrue(secondSignal.waitForExistence(timeout: 5))
        let pageNumber = app.staticTexts.matching(identifier: "pdf-reader.contents-page").element(boundBy: 1)
        XCTAssertTrue(pageNumber.exists)
        tapRowWhitespace(between: secondSignal, and: pageNumber, in: app)
        XCTAssertTrue(
            waitForValue("Page 2 of 2", on: element("pdf-reader.page", in: app)),
            "Tapping PDF outline whitespace should navigate to the selected page."
        )
        element("pdf-reader.contents-close", in: app).tap()

        let search = element("pdf-reader.search", in: app)
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        let field = element("pdf-reader.search-field", in: app)
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("lighthouse")
        field.typeText("\n")
        XCTAssertEqual(
            "Result 1 of 1",
            element("pdf-reader.search-results", in: app).label
        )
        attachScreenshot(of: app, named: "pdf-reader-native-outline-search")
    }

    @MainActor
    func testMovieVideoGridUsesCompactMetadataWithoutEpisodeBadges() throws {
        let app = signedInApplication()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10))
        let browseScreen = element("shell.search", in: app)
        selectBrowse(tabBar.buttons["Browse"], screen: browseScreen, tabBar: tabBar)

        let videoMode = element("shell.search.mode.video", in: app)
        XCTAssertTrue(videoMode.waitForExistence(timeout: 5))
        videoMode.tap()

        XCTAssertTrue(tabBar.buttons["Movies"].waitForExistence(timeout: 5))
        tabBar.buttons["Videos"].tap()
        XCTAssertTrue(element("entity.grid", in: app).waitForExistence(timeout: 10))
        XCTAssertTrue(
            element(
                "entity.thumbnail.11111111-1111-1111-1111-111111111111",
                in: app
            ).waitForExistence(timeout: 10)
        )
        XCTAssertFalse(app.staticTexts["E0"].exists)
        XCTAssertFalse(app.staticTexts["E1"].exists)
        attachScreenshot(of: app, named: "movie-video-grid-compact-metadata")
    }

    @MainActor
    func testEntityDetailUsesNativeRatingControlsAndChildGrid() throws {
        let app = signedInApplication()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10))
        let browseScreen = element("shell.search", in: app)
        selectBrowse(tabBar.buttons["Browse"], screen: browseScreen, tabBar: tabBar)

        let searchField = app.searchFields.firstMatch
        if searchField.waitForExistence(timeout: 5) {
            searchField.tap()
            searchField.typeText("Mock Series")
        } else {
            app.windows.firstMatch
                .coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.23))
                .tap()
            XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
            app.typeText("Mock Series")
        }

        let movieResult = element(
            "shell.search.result.55555555-5555-5555-5555-555555555555",
            in: app
        )
        XCTAssertTrue(movieResult.waitForExistence(timeout: 10))
        movieResult.tap()

        XCTAssertTrue(element("entity-detail.content", in: app).waitForExistence(timeout: 10))
        let moreActions = element("entity-detail.more-actions", in: app)
        XCTAssertTrue(moreActions.waitForExistence(timeout: 5))
        moreActions.tap()
        XCTAssertTrue(element("entity-detail.action.favorite", in: app).isEnabled)
        XCTAssertTrue(element("entity-detail.action.organized", in: app).isEnabled)
        element("entity-detail.action.favorite", in: app).tap()
        for rating in 1...5 {
            XCTAssertTrue(element("entity-detail.rating.\(rating)", in: app).exists)
        }
        XCTAssertFalse(app.staticTexts["Organized"].exists)
        attachScreenshot(of: app, named: "entity-detail-native-controls")

        let firstChild = element(
            "entity-detail.child.10101010-1010-1010-1010-101010101010",
            in: app
        )
        let secondChild = element(
            "entity-detail.child.20202020-2020-2020-2020-202020202020",
            in: app
        )
        for _ in 0..<4 where !firstChild.exists {
            app.swipeUp()
        }
        XCTAssertTrue(firstChild.waitForExistence(timeout: 5))
        XCTAssertTrue(secondChild.exists)
        XCTAssertEqual(firstChild.frame.minY, secondChild.frame.minY, accuracy: 2)
        attachScreenshot(of: app, named: "entity-detail-native-child-grid")
    }

    @MainActor
    func testAuthenticationUsesNativeContentHierarchy() throws {
        let app = launchedApplication()

        XCTAssertTrue(element("auth.brand.logo", in: app).waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Connect to Prismedia"].exists)
        XCTAssertFalse(
            app.staticTexts["PRISMEDIA"].exists,
            "The native auth screen should use the mark without a web-style wordmark lockup"
        )

        let primaryAction = element("auth.primary", in: app)
        let window = app.windows.firstMatch
        XCTAssertTrue(primaryAction.exists)
        XCTAssertGreaterThanOrEqual(
            primaryAction.frame.height,
            44,
            "The native glass action must retain Apple's minimum touch target."
        )
        XCTAssertLessThanOrEqual(
            primaryAction.frame.height,
            76,
            "The primary action should stay compact while allowing native glass metrics and Dynamic Type."
        )
        XCTAssertLessThan(
            window.frame.maxY - primaryAction.frame.maxY,
            80,
            "The primary action should stay anchored to the bottom safe area"
        )
    }

    @MainActor
    func testSignInThenBrowseThroughPermanentBrowseTab() throws {
        let app = launchedApplication()

        attachScreenshot(of: app, named: "auth-server")
        XCTAssertTrue(
            element("auth.brand.logo", in: app).waitForExistence(timeout: 10),
            "Authentication should use the real Prismedia logo"
        )
        XCTAssertTrue(app.staticTexts["Connect to Prismedia"].exists)

        // Server step
        advanceToLogin(serverURL: "localhost:8899", in: app)

        // Login step (mock server reports needsSetup=false)
        attachScreenshot(of: app, named: "auth-login")
        submitCredentials(username: "test", password: "test1234", in: app)

        // Shell lands in Overview with one system-owned tab bar.
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10), "The native tab bar should appear after sign-in")
        XCTAssertEqual(app.tabBars.count, 1, "The shell must render exactly one tab bar")
        XCTAssertTrue(tabBar.buttons["Dashboard"].exists)
        XCTAssertTrue(tabBar.buttons["Browse"].exists)
        XCTAssertTrue(tabBar.buttons["Stats"].exists)
        XCTAssertEqual(
            tabBar.buttons.matching(NSPredicate(format: "label == %@", "Browse")).count,
            1,
            "Browse must be one permanent shell destination, not a duplicate Overview tab"
        )
        XCTAssertFalse(
            app.buttons["App Navigation"].exists,
            "The obsolete sheet toggle must not remain beside the permanent Browse tab"
        )

        // Dashboard is the real overview destination.
        XCTAssertTrue(
            element("shell.dashboard", in: app).waitForExistence(timeout: 10),
            "Dashboard should render its native overview"
        )
        attachScreenshot(of: app, named: "shell-overview")

        // Browse is a real destination. It does not present a sheet and its
        // browse hub remains inside the same system-owned tab hierarchy.
        let browseTab = tabBar.buttons["Browse"]
        let browseScreen = element("shell.search", in: app)
        selectBrowse(browseTab, screen: browseScreen, tabBar: tabBar)
        XCTAssertFalse(element("shell.navigation.panel", in: app).exists)
        attachScreenshot(of: app, named: "shell-browse")

        // A URL-encoded multi-word query should reach the mock API and render
        // the matching result in Browse's system search field.
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(
            searchField.waitForExistence(timeout: 5),
            "Browse must show its system search field immediately."
        )
        searchField.tap()
        searchField.typeText("Movie One")

        let movieResult = element(
            "shell.search.result.33333333-3333-3333-3333-333333333333",
            in: app
        )
        XCTAssertTrue(movieResult.waitForExistence(timeout: 10))
        attachScreenshot(of: app, named: "shell-browse-search-results")

        // Search and library grids share the same typed entity destination.
        movieResult.tap()
        XCTAssertTrue(
            element("entity-detail.content", in: app).waitForExistence(timeout: 10),
            "A search result should open the selected entity, not only switch sections"
        )
        XCTAssertTrue(app.staticTexts["Mock Movie One"].exists)
        attachScreenshot(of: app, named: "entity-detail-from-search")
        navigateBack(in: app)

        let closeSearch = app.buttons["Close"]
        XCTAssertTrue(closeSearch.waitForExistence(timeout: 5))
        closeSearch.tap()

        // Mode cards replace the flyout as the top-level navigation path.
        let videoMode = element("shell.search.mode.video", in: app)
        XCTAssertTrue(videoMode.waitForExistence(timeout: 5))
        videoMode.tap()

        // The same system tab bar re-populates with Video destinations.
        let moviesTab = tabBar.buttons["Movies"]
        XCTAssertTrue(moviesTab.waitForExistence(timeout: 5), "A mode card should switch the adaptive tab set")
        XCTAssertEqual(app.tabBars.count, 1)
        XCTAssertTrue(tabBar.buttons["Series"].exists)
        XCTAssertTrue(tabBar.buttons["Videos"].exists)
        XCTAssertTrue(tabBar.buttons["Browse"].exists, "Browse must remain available in every mode")
        XCTAssertFalse(tabBar.buttons["Dashboard"].exists, "Overview tabs should be gone in Video mode")
        moviesTab.tap()
        XCTAssertTrue(moviesTab.isSelected)
        XCTAssertTrue(element("entity.grid", in: app).waitForExistence(timeout: 10))
        let movieThumbnail = element(
            "entity.thumbnail.33333333-3333-3333-3333-333333333333",
            in: app
        )
        XCTAssertTrue(movieThumbnail.waitForExistence(timeout: 10))
        attachScreenshot(of: app, named: "video-mode")

        movieThumbnail.tap()
        XCTAssertTrue(element("entity-detail.content", in: app).waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Native detail fixture for Mock Movie One."].exists)
        attachScreenshot(of: app, named: "entity-detail-from-grid")
        navigateBack(in: app)

        // The user/account picker belongs in the native top toolbar rather
        // than at the bottom of a navigation sheet.
        selectBrowse(tabBar.buttons["Browse"], screen: browseScreen, tabBar: tabBar)
        let accountMenu = app.buttons["shell.account"].firstMatch
        XCTAssertTrue(accountMenu.waitForExistence(timeout: 5))
        XCTAssertEqual(accountMenu.label, "Account, Test User")
        accountMenu.tap()
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Sign Out"].exists)
    }

    @MainActor
    func testInvalidCredentialsStayInBrandedLoginFlow() throws {
        let app = launchedApplication()

        XCTAssertTrue(element("auth.brand.logo", in: app).waitForExistence(timeout: 10))
        advanceToLogin(serverURL: "localhost:8899", in: app)
        submitCredentials(username: "test", password: "not-the-password", in: app)

        XCTAssertTrue(
            app.staticTexts["Invalid username or password."].waitForExistence(timeout: 10)
        )
        XCTAssertTrue(element("auth.error", in: app).exists)
        XCTAssertEqual(app.textFields["Username"].value as? String, "test")
        XCTAssertTrue(element("auth.change-server", in: app).exists)
        attachScreenshot(of: app, named: "auth-error")
    }

    /// Live-contract check against a local dev server, if one is running:
    /// probing the server must reach the login step, and a bad login must
    /// surface the server's real invalid-credentials message. Skipped when no
    /// dev server is up. Uses a single attempt — far below the auth throttle.
    @MainActor
    func testDevServerProbeAndLoginErrorPath() async throws {
        let devServerURL = URL(string: "http://localhost:8008/api/health")!
        guard (try? await URLSession.shared.data(from: devServerURL)) != nil else {
            throw XCTSkip("No dev server on localhost:8008")
        }

        let app = launchedApplication()
        advanceToLogin(serverURL: "localhost:8008", in: app)
        submitCredentials(username: "uitest-nobody", password: "wrong-password", in: app)

        XCTAssertTrue(
            app.staticTexts["Invalid username or password."].waitForExistence(timeout: 10),
            "Dev server should reject bogus credentials with the mapped error message"
        )
    }

    @MainActor
    private func attachScreenshot(of app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    private func signedInApplication(
        initialEntityID: String? = nil,
        kind: String? = nil,
        startVideo: Bool = false,
        startFullscreen: Bool = false,
        modeID: String? = nil,
        destinationID: String? = nil
    ) -> XCUIApplication {
        let app = launchedApplication(preauthenticated: true, launch: false)
        app.launchEnvironment["PRISMEDIA_UI_TEST_DISABLE_HERO_AUTO_ADVANCE"] = "1"
        if let initialEntityID, let kind {
            app.launchEnvironment["PRISMEDIA_UI_TEST_ENTITY_ID"] = initialEntityID
            app.launchEnvironment["PRISMEDIA_UI_TEST_ENTITY_KIND"] = kind
        }
        if startVideo {
            app.launchEnvironment["PRISMEDIA_UI_TEST_START_VIDEO"] = "1"
        }
        if startFullscreen {
            app.launchEnvironment["PRISMEDIA_UI_TEST_START_FULLSCREEN"] = "1"
        }
        if let modeID {
            app.launchEnvironment["PRISMEDIA_UI_TEST_MODE_ID"] = modeID
        }
        if let destinationID {
            app.launchEnvironment["PRISMEDIA_UI_TEST_DESTINATION_ID"] = destinationID
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
        XCTAssertTrue(
            app.textFields["Username"].waitForExistence(timeout: 10),
            "Login form should appear after probing the server"
        )
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
    private func tapTrailingRowWhitespace(in row: XCUIElement) {
        XCTAssertTrue(row.exists)
        row.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
    }

    @MainActor
    private func tapRowWhitespace(
        between leadingLabel: XCUIElement,
        and trailingLabel: XCUIElement,
        in app: XCUIApplication
    ) {
        let whitespaceX = (leadingLabel.frame.maxX + trailingLabel.frame.minX) / 2
        XCTAssertGreaterThan(whitespaceX, leadingLabel.frame.maxX + 8)
        let appFrame = app.frame
        app.coordinate(
            withNormalizedOffset: CGVector(
                dx: (whitespaceX - appFrame.minX) / appFrame.width,
                dy: (leadingLabel.frame.midY - appFrame.minY) / appFrame.height
            )
        ).tap()
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
    private func waitForNotHittable(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "hittable == false"),
            object: element
        )
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    @MainActor
    private func waitForValue(
        _ value: String,
        on element: XCUIElement,
        timeout: TimeInterval = 5
    ) -> Bool {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", value),
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
    private func navigateBack(in app: XCUIApplication) {
        let backButton = app.buttons["BackButton"]
        XCTAssertTrue(backButton.waitForExistence(timeout: 5))
        backButton.tap()
    }

    @MainActor
    private func search(_ query: String, in app: XCUIApplication) {
        let searchField = app.searchFields.firstMatch
        if searchField.waitForExistence(timeout: 5) {
            searchField.tap()
            searchField.typeText(query)
            return
        }

        app.windows.firstMatch
            .coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.23))
            .tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
        app.typeText(query)
    }

    @MainActor
    private func waitForElement(
        _ identifier: String,
        in app: XCUIApplication,
        labelContaining text: String,
        timeout: TimeInterval = 5
    ) -> Bool {
        app.descendants(matching: .any)
            .matching(identifier: identifier)
            .matching(NSPredicate(format: "label CONTAINS %@", text))
            .firstMatch
            .waitForExistence(timeout: timeout)
    }

    @MainActor
    private func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    @MainActor
    private func imageGridOrder(_ imageIDs: [String], in app: XCUIApplication) -> [String] {
        imageIDs
            .compactMap { imageID -> (id: String, frame: CGRect)? in
                let thumbnail = element("entity.thumbnail.\(imageID)", in: app)
                guard thumbnail.exists else { return nil }
                return (imageID, thumbnail.frame)
            }
            .sorted { lhs, rhs in
                if abs(lhs.frame.midY - rhs.frame.midY) < 2 {
                    return lhs.frame.minX < rhs.frame.minX
                }
                return lhs.frame.minY < rhs.frame.minY
            }
            .map(\.id)
    }

    @MainActor
    private func selectBrowse(
        _ button: XCUIElement,
        screen: XCUIElement,
        tabBar: XCUIElement
    ) {
        button.tap()
        if !screen.waitForExistence(timeout: 2) {
            // Derive a fallback from the visible frame so compact and regular
            // tab layouts remain selectable across simulator versions.
            let tabFrame = tabBar.frame
            let buttonFrame = button.frame
            let normalizedPoint = CGVector(
                dx: (buttonFrame.midX - tabFrame.minX) / tabFrame.width,
                dy: (buttonFrame.midY - tabFrame.minY) / tabFrame.height
            )
            tabBar.coordinate(withNormalizedOffset: normalizedPoint).tap()
        }
        XCTAssertTrue(screen.waitForExistence(timeout: 5))
    }
}
