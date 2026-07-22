import XCTest

final class PrismediaTVCollectionDetailUITests: XCTestCase {
    @MainActor
    func testCollectionGridHeaderControlsRemainAvailable() {
        let app = launchCollectionDetail()
        let firstItem = focusedSurface(
            "entity.thumbnail.media.33333333-3333-3333-3333-333333333333",
            in: app
        )

        XCTAssertTrue(firstItem.waitForExistence(timeout: 20))
        let sort = element(label: "Sort", in: app)
        XCTAssertTrue(element(label: "Display options", in: app).exists)
        XCTAssertTrue(sort.exists)
        XCTAssertTrue(element(label: "Filters", in: app).exists)

        for _ in 0..<7 {
            XCUIRemote.shared.press(.right)
        }
        XCUIRemote.shared.press(.up)
        XCUIRemote.shared.press(.select)

        XCTAssertTrue(
            element(label: "Title", in: app).waitForExistence(timeout: 5),
            "The embedded EntityGrid sort control should open its native menu."
        )
        XCUIRemote.shared.press(.menu)
    }

    @MainActor
    func testLongPressRetainsAddToCollectionMenu() {
        let app = launchCollectionDetail()
        let firstItem = focusedSurface(
            "entity.thumbnail.media.33333333-3333-3333-3333-333333333333",
            in: app
        )

        XCTAssertTrue(firstItem.waitForExistence(timeout: 20))

        XCUIRemote.shared.press(.select, forDuration: 1.2)

        XCTAssertTrue(
            element(label: "Add to Collection", in: app).waitForExistence(timeout: 5),
            "A long press on a tvOS collection item should retain its add-to-collection menu."
        )
    }

    @MainActor
    func testCollectionOpensOnFirstGridItemAndUpMovesToCollectionsTab() {
        let app = launchCollectionDetail()
        let firstItem = focusedSurface(
            "entity.thumbnail.media.33333333-3333-3333-3333-333333333333",
            in: app
        )

        XCTAssertTrue(firstItem.waitForExistence(timeout: 20))
        XCTAssertTrue(waitForFocus(on: firstItem, timeout: 8))
        XCTAssertTrue(element("entity-detail.hero-information", in: app).exists)
        XCTAssertTrue(element(label: "Display options", in: app).exists)
        XCTAssertTrue(element(label: "Sort", in: app).exists)
        XCTAssertTrue(element(label: "Filters", in: app).exists)

        XCUIRemote.shared.press(.up)

        XCTAssertTrue(
            waitForFocus(on: element(label: "Collections", in: app), timeout: 5),
            "One Up press from the initial collection card should focus the Collections tab."
        )
        XCTAssertTrue(
            element("entity-detail.hero-information", in: app).exists,
            "Moving to the tab bar should retain the collection overview."
        )
    }

    @MainActor
    func testFirstLateralMoveAdvancesFocus() {
        let app = launchCollectionDetail()
        let firstItem = focusedSurface(
            "entity.thumbnail.media.33333333-3333-3333-3333-333333333333",
            in: app
        )
        let secondItem = button(
            "entity.thumbnail.88888888-8888-8888-8888-888888888888",
            in: app
        )

        XCTAssertTrue(firstItem.waitForExistence(timeout: 20))
        XCTAssertTrue(waitForFocus(on: firstItem, timeout: 8))

        XCUIRemote.shared.press(.right)

        XCTAssertTrue(waitForFocus(on: secondItem, timeout: 5))
    }

    @MainActor
    private func launchCollectionDetail() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-prismedia-reset-session", "-prismedia-ui-testing"]
        app.launchEnvironment["PRISMEDIA_UI_TEST_SESSION_SERVER"] =
            ProcessInfo.processInfo.environment["PRISMEDIA_UI_TEST_SERVER"]
            ?? "http://localhost:8899"
        app.launchEnvironment["PRISMEDIA_UI_TEST_SESSION_TOKEN"] = "mock-session-token"
        app.launchEnvironment["PRISMEDIA_UI_TEST_DISABLE_HERO_AUTO_ADVANCE"] = "1"
        app.launchEnvironment["PRISMEDIA_UI_TEST_ENTITY_ID"] =
            "00000000-0000-0000-0000-000000000000"
        app.launchEnvironment["PRISMEDIA_UI_TEST_ENTITY_KIND"] = "collection"
        app.launch()
        return app
    }

    @MainActor
    private func waitForFocus(on element: XCUIElement, timeout: TimeInterval) -> Bool {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "hasFocus == true"),
            object: element
        )
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    @MainActor
    private func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    @MainActor
    private func button(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.buttons[identifier]
    }

    @MainActor
    private func focusedSurface(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(identifier: identifier)
            .matching(NSPredicate(format: "hasFocus == true"))
            .firstMatch
    }

    @MainActor
    private func element(label: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@", label))
            .firstMatch
    }
}
