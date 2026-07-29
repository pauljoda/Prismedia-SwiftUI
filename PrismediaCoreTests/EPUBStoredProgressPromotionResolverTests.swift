import XCTest

@testable import PrismediaCore

final class EPUBStoredProgressPromotionResolverTests: XCTestCase {
    func testLaterStoredChapterPromotesTheCanonicalServerCursor() throws {
        let storedLocation = #"{"href":"Text/Catelyn.xhtml","locations":{"progression":0.25}}"#
        let request = try XCTUnwrap(
            EPUBStoredProgressPromotionResolver().request(
                bookID: bookID,
                storedLocation: storedLocation,
                ranges: ranges,
                mode: .paged,
                progress: progress(index: 9_500, location: "epubcfi(/6/144!/4/2/2:10)")
            )
        )

        XCTAssertEqual(request.currentEntityID, bookID)
        XCTAssertEqual(request.index, 9_700)
        XCTAssertEqual(request.location, storedLocation)
        XCTAssertNil(request.activitySeconds)
    }

    func testOlderStoredChapterCannotMoveTheCanonicalCursorBackward() {
        let storedLocation = #"{"href":"Text/Jon.xhtml","locations":{"progression":0.9}}"#

        XCTAssertNil(
            EPUBStoredProgressPromotionResolver().request(
                bookID: bookID,
                storedLocation: storedLocation,
                ranges: ranges,
                mode: .paged,
                progress: progress(index: 9_700, location: nil)
            )
        )
    }

    func testOlderExactPositionInTheSameChapterDoesNotReplaceServerProgress() {
        let storedLocation = #"{"href":"Text/Catelyn.xhtml","locations":{"progression":0.25}}"#
        let serverLocation = #"{"href":"Text/Catelyn.xhtml","locations":{"progression":0.3}}"#

        XCTAssertNil(
            EPUBStoredProgressPromotionResolver().request(
                bookID: bookID,
                storedLocation: storedLocation,
                ranges: ranges,
                mode: .paged,
                progress: progress(index: 9_500, location: serverLocation)
            )
        )
    }

    private let bookID = UUID(uuidString: "10000000-0000-0000-0000-000000000001")!

    private var ranges: [EPUBReadingProgressRange] {
        [
            EPUBReadingProgressRange(
                location: "Text/Jon.xhtml",
                startFraction: 0.8,
                endFraction: 0.96
            ),
            EPUBReadingProgressRange(
                location: "Text/Catelyn.xhtml",
                startFraction: 0.96,
                endFraction: 1
            ),
        ]
    }

    private func progress(index: Int, location: String?) -> EntityProgressCapability {
        EntityProgressCapability(
            currentEntityID: bookID,
            unit: .cfi,
            index: index,
            total: 10_000,
            mode: .paged,
            completedAt: nil,
            updatedAt: nil,
            workIndex: index,
            workTotal: 10_000,
            location: location
        )
    }
}
