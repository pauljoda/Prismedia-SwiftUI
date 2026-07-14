import Foundation
import XCTest

@testable import PrismediaCore

final class EPUBBookmarkBehaviorTests: XCTestCase {
    func testBookmarksRoundTripWithTimestampAndOneToggleSelection() throws {
        let suiteName = "EPUBBookmarkBehaviorTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = EPUBBookmarkStore(
            defaults: defaults,
            scope: EPUBBookmarkScope(
                serverURL: try XCTUnwrap(URL(string: "https://reader.example")),
                userID: UUID()
            )
        )
        let bookID = UUID()
        let firstBookmark = EPUBBookmark(
            id: UUID(),
            locator: "chapter-4",
            chapterTitle: "A Narrow Escape",
            chapterPage: 10,
            chapterPageCount: 51,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let secondBookmark = EPUBBookmark(
            id: UUID(),
            locator: "appendix-a",
            chapterTitle: "Appendix A",
            chapterPage: 1,
            chapterPageCount: 12,
            createdAt: Date(timeIntervalSince1970: 1_700_000_100)
        )
        let expected = EPUBBookmarksState(
            bookmarks: [firstBookmark, secondBookmark],
            toggleBookmarkID: secondBookmark.id
        )

        store.save(expected, bookID: bookID)

        XCTAssertEqual(store.load(bookID: bookID), expected)
        XCTAssertEqual(store.load(bookID: UUID()), EPUBBookmarksState())
    }

    func testBookmarksAreIsolatedByServerAndUser() throws {
        let suiteName = "EPUBBookmarkBehaviorTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let bookID = UUID()
        let userID = UUID()
        let bookmark = EPUBBookmark(
            id: UUID(),
            locator: "chapter-4",
            chapterTitle: "A Narrow Escape",
            chapterPage: 10,
            chapterPageCount: 51,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let firstStore = EPUBBookmarkStore(
            defaults: defaults,
            scope: EPUBBookmarkScope(
                serverURL: try XCTUnwrap(URL(string: "https://first.example")),
                userID: userID
            )
        )
        let otherUserStore = EPUBBookmarkStore(
            defaults: defaults,
            scope: EPUBBookmarkScope(
                serverURL: try XCTUnwrap(URL(string: "https://first.example")),
                userID: UUID()
            )
        )
        let otherServerStore = EPUBBookmarkStore(
            defaults: defaults,
            scope: EPUBBookmarkScope(
                serverURL: try XCTUnwrap(URL(string: "https://second.example")),
                userID: userID
            )
        )

        firstStore.save(EPUBBookmarksState(bookmarks: [bookmark]), bookID: bookID)

        XCTAssertEqual(firstStore.load(bookID: bookID).bookmarks, [bookmark])
        XCTAssertEqual(otherUserStore.load(bookID: bookID), EPUBBookmarksState())
        XCTAssertEqual(otherServerStore.load(bookID: bookID), EPUBBookmarksState())
    }

    func testDecodingNormalizesPageBoundsAndDanglingToggleSelection() throws {
        let bookmarkID = UUID()
        let danglingID = UUID()
        let data = try XCTUnwrap(
            """
            {
              "bookmarks": [{
                "id": "\(bookmarkID.uuidString)",
                "locator": "chapter-4",
                "chapterTitle": "A Narrow Escape",
                "chapterPage": 99,
                "chapterPageCount": 3,
                "createdAt": 0
              }],
              "toggleBookmarkID": "\(danglingID.uuidString)"
            }
            """.data(using: .utf8)
        )

        let state = try JSONDecoder().decode(EPUBBookmarksState.self, from: data)

        XCTAssertEqual(state.bookmarks.first?.chapterPage, 3)
        XCTAssertEqual(state.bookmarks.first?.chapterPageCount, 3)
        XCTAssertNil(state.toggleBookmarkID)
    }

    func testToggleBookmarkReturnsToTheLocationCapturedByTheFirstPress() {
        var navigation = EPUBToggleBookmarkNavigation()

        let bookmarkDestination = navigation.destination(
            toggleBookmarkLocator: "appendix-a",
            currentLocator: "chapter-4-page-10"
        )
        XCTAssertFalse(navigation.shouldRecordProgress)
        let returnDestination = navigation.destination(
            toggleBookmarkLocator: "appendix-a",
            currentLocator: "appendix-a"
        )

        XCTAssertEqual(bookmarkDestination, "appendix-a")
        XCTAssertEqual(returnDestination, "chapter-4-page-10")
        XCTAssertFalse(navigation.isReturnAvailable)
        XCTAssertTrue(navigation.shouldRecordProgress)
    }

    func testChangingTheToggleBookmarkClearsAnObsoleteReturnLocation() {
        var navigation = EPUBToggleBookmarkNavigation()
        _ = navigation.destination(
            toggleBookmarkLocator: "appendix-a",
            currentLocator: "chapter-4-page-10"
        )

        navigation.reset()

        XCTAssertFalse(navigation.isReturnAvailable)
        XCTAssertEqual(
            navigation.destination(
                toggleBookmarkLocator: "map",
                currentLocator: "chapter-7-page-3"
            ),
            "map"
        )
    }
}
