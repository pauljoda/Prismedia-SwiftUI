import XCTest

@testable import PrismediaCore

final class EPUBReadingPresentationTests: XCTestCase {
    func testChapterProgressUsesTheRenderedViewportForPageTenOfFiftyOne() {
        let progress = EPUBChapterProgress(
            chapterTitle: "The First Signal",
            visibleProgression: (9.0 / 51.0)...(10.0 / 51.0)
        )

        XCTAssertEqual(progress.chapterTitle, "The First Signal")
        XCTAssertEqual(progress.pageNumber, 10)
        XCTAssertEqual(progress.pageCount, 51)
        XCTAssertEqual(progress.counterText, "10 / 51")
    }

    func testChapterProgressClampsAtTheFirstAndLastPage() {
        XCTAssertEqual(
            EPUBChapterProgress(
                chapterTitle: "Start",
                visibleProgression: -1 ... -0.75
            ).pageNumber,
            1
        )
        XCTAssertEqual(
            EPUBChapterProgress(
                chapterTitle: "End",
                visibleProgression: 0.75...1
            ).pageNumber,
            4
        )
    }

    func testSearchResultKeepsChapterPageAndSurroundingText() {
        let result = EPUBSearchResult(
            id: "result-1",
            title: "Appendix A",
            before: "The index points toward the ",
            highlight: "signal",
            after: " recorded beyond the harbor.",
            chapterPage: 10,
            chapterPageCount: 51,
            location: "appendix-a"
        )

        XCTAssertEqual(result.locationLabel, "Page 10 of 51")
        XCTAssertEqual(
            result.excerpt,
            "The index points toward the signal recorded beyond the harbor."
        )
    }

    func testReaderDismissRequiresADominantDownwardSwipe() {
        XCTAssertTrue(ReaderDismissGesture.shouldDismiss(deltaX: 8, deltaY: 90))
        XCTAssertFalse(ReaderDismissGesture.shouldDismiss(deltaX: 90, deltaY: 8))
        XCTAssertFalse(ReaderDismissGesture.shouldDismiss(deltaX: 8, deltaY: -90))
        XCTAssertFalse(ReaderDismissGesture.shouldDismiss(deltaX: 8, deltaY: 40))
    }
}
