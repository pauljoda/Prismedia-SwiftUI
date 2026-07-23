import Foundation
import XCTest

@testable import PrismediaCore

final class EPUBLocatorStoreTests: XCTestCase {
    func testLocatorsRemainLocalAndBookScoped() throws {
        let suiteName = "EPUBLocatorStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = EPUBLocatorStore(defaults: defaults)
        let firstBook = UUID()
        let secondBook = UUID()

        store.save("{\"href\":\"chapter-2.xhtml\"}", bookID: firstBook)

        XCTAssertEqual(store.load(bookID: firstBook), "{\"href\":\"chapter-2.xhtml\"}")
        XCTAssertNil(store.load(bookID: secondBook))
    }

    func testDisabledStoreDoesNotPersistPreviewState() {
        let bookID = UUID()

        EPUBLocatorStore.disabled.save("locator", bookID: bookID)

        XCTAssertNil(EPUBLocatorStore.disabled.load(bookID: bookID))
    }

    func testChapterLocatorsRemainIndependentFromCurrentBookLocation() throws {
        let suiteName = "EPUBLocatorStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = EPUBLocatorStore(defaults: defaults)
        let bookID = UUID()

        store.save(
            "chapter-1.xhtml#prismedia-progress=0.72",
            bookID: bookID,
            chapterLocation: "chapter-1.xhtml"
        )
        store.save(
            "chapter-2.xhtml#prismedia-progress=0.08",
            bookID: bookID,
            chapterLocation: "chapter-2.xhtml"
        )

        XCTAssertEqual(
            store.load(bookID: bookID, chapterLocation: "chapter-1.xhtml"),
            "chapter-1.xhtml#prismedia-progress=0.72"
        )
        XCTAssertEqual(
            store.load(bookID: bookID, chapterLocation: "chapter-2.xhtml"),
            "chapter-2.xhtml#prismedia-progress=0.08"
        )
        XCTAssertEqual(
            store.load(bookID: bookID),
            "chapter-2.xhtml#prismedia-progress=0.08"
        )
    }
}
