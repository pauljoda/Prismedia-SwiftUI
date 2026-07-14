import XCTest

@testable import PrismediaCore

final class ComicReaderBehaviorTests: XCTestCase {
    func testTouchTapZonesMatchTheMobilePWAThirds() {
        XCTAssertEqual(ComicReaderNavigation.tapZone(x: 10, width: 300), .previous)
        XCTAssertEqual(ComicReaderNavigation.tapZone(x: 150, width: 300), .controls)
        XCTAssertEqual(ComicReaderNavigation.tapZone(x: 290, width: 300), .next)
        XCTAssertEqual(ComicReaderNavigation.tapZone(x: 0, width: 0), .controls)
    }

    func testDoublePageModeKeepsTheFirstPageAsAnIsolatedCover() {
        let options = ComicReaderOptions(pageMode: .double, firstPageIsCover: true)

        XCTAssertEqual(ComicReaderNavigation.spread(index: 0, total: 6, options: options), [0])
        XCTAssertEqual(ComicReaderNavigation.nextIndex(from: 0, total: 6, options: options), 1)
        XCTAssertEqual(ComicReaderNavigation.spread(index: 1, total: 6, options: options), [1, 2])
        XCTAssertEqual(ComicReaderNavigation.nextIndex(from: 1, total: 6, options: options), 3)
        XCTAssertEqual(ComicReaderNavigation.previousIndex(from: 3, total: 6, options: options), 1)
    }

    func testDoublePageModePairsFromTheFirstPageWhenCoverIsolationIsOff() {
        let options = ComicReaderOptions(pageMode: .double, firstPageIsCover: false)

        XCTAssertEqual(ComicReaderNavigation.spread(index: 0, total: 5, options: options), [0, 1])
        XCTAssertEqual(ComicReaderNavigation.nextIndex(from: 0, total: 5, options: options), 2)
        XCTAssertEqual(ComicReaderNavigation.previousIndex(from: 4, total: 5, options: options), 2)
    }

    func testPagedGestureOnlyCommitsDominantSwipesPastFiftyPoints() {
        XCTAssertEqual(ComicReaderNavigation.gesture(deltaX: -80, deltaY: 10), .next)
        XCTAssertEqual(ComicReaderNavigation.gesture(deltaX: 80, deltaY: 10), .previous)
        XCTAssertEqual(ComicReaderNavigation.gesture(deltaX: 5, deltaY: 80), .dismiss)
        XCTAssertEqual(ComicReaderNavigation.gesture(deltaX: 45, deltaY: 0), .none)
        XCTAssertEqual(ComicReaderNavigation.gesture(deltaX: 70, deltaY: 60), .none)
        XCTAssertEqual(ComicReaderNavigation.gesture(deltaX: 0, deltaY: -80), .none)
    }

    func testPrewarmingKeepsTwoDecodedPagesOnEitherSideOfTheVisibleSpread() {
        XCTAssertEqual(
            ComicReaderNavigation.preloadIndexes(
                index: 3,
                total: 8,
                options: .init(pageMode: .single, firstPageIsCover: true)
            ),
            [1, 2, 4, 5]
        )
        XCTAssertEqual(
            ComicReaderNavigation.preloadIndexes(
                index: 1,
                total: 8,
                options: .init(pageMode: .double, firstPageIsCover: true)
            ),
            [0, 3, 4]
        )
    }

    func testReadingProgressCardUsesWholeBookPositionAndChapterContext() throws {
        let chapterID = UUID(uuidString: "00000000-0000-0000-0000-000000000222")!
        let progress = EntityProgressCapability(
            currentEntityID: chapterID,
            unit: .page,
            index: 4,
            total: 10,
            mode: .webtoon,
            completedAt: nil,
            updatedAt: nil,
            workIndex: 14,
            workTotal: 30,
            location: nil
        )
        let chapters = [
            BookChapterSummary(id: chapterID, title: "Arrival", sortOrder: 1, pageCount: 10)
        ]

        let card = try XCTUnwrap(ReadingProgressPresentation(progress: progress, chapters: chapters))

        XCTAssertEqual(card.status, .inProgress)
        XCTAssertEqual(card.percent, 50)
        XCTAssertEqual(card.positionLabel, "Book page 15 of 30")
        XCTAssertEqual(card.contextLabel, "Ch. 2: Arrival")
        XCTAssertTrue(card.canResume)
        XCTAssertTrue(card.canStartOver)
        XCTAssertEqual(card.readerMode, .webtoon)
    }

    func testCompletedReadingProgressHidesResumeButKeepsStartOver() throws {
        let chapterID = UUID(uuidString: "00000000-0000-0000-0000-000000000333")!
        let progress = EntityProgressCapability(
            currentEntityID: chapterID,
            unit: .page,
            index: 9,
            total: 10,
            mode: .paged,
            completedAt: "2026-07-11T10:00:00Z",
            updatedAt: nil,
            workIndex: 29,
            workTotal: 30,
            location: nil
        )

        let card = try XCTUnwrap(
            ReadingProgressPresentation(
                progress: progress,
                chapters: [.init(id: chapterID, title: "Finale", sortOrder: 2, pageCount: 10)]
            ))

        XCTAssertEqual(card.status, .completed)
        XCTAssertEqual(card.percent, 100)
        XCTAssertNil(card.positionLabel)
        XCTAssertFalse(card.canResume)
        XCTAssertTrue(card.canStartOver)
    }
}
