import XCTest

@testable import PrismediaCore

final class ReadingProgressPresentationTests: XCTestCase {
    func testChapterCursorCanMoveBackwardWithoutReducingBookCoverage() throws {
        let chapterID = UUID()
        let progress = EntityProgressCapability(
            currentEntityID: chapterID,
            unit: .page,
            index: 4,
            total: 20,
            mode: .paged,
            completedAt: nil,
            updatedAt: nil,
            workIndex: 20,
            workTotal: 100,
            location: nil,
            consumedCount: 75,
            consumedTotal: 100,
            consumedPercent: 0.75
        )

        let presentation = try XCTUnwrap(
            ReadingProgressPresentation(
                progress: progress,
                chapters: [
                    BookChapterSummary(
                        id: chapterID,
                        title: "Earlier Chapter",
                        sortOrder: 2,
                        pageCount: 20
                    )
                ]
            )
        )

        XCTAssertEqual(presentation.percent, 75)
        XCTAssertEqual(presentation.positionLabel, "Book page 21 of 100")
        XCTAssertEqual(presentation.contextLabel, "Ch. 3: Earlier Chapter")
    }

    func testTimedBookShowsCurrentTimeSeparatelyFromConsumedCoverage() throws {
        let progress = EntityProgressCapability(
            currentEntityID: UUID(),
            unit: .second,
            index: 300,
            total: 1_000,
            mode: nil,
            completedAt: nil,
            updatedAt: nil,
            workIndex: nil,
            workTotal: nil,
            location: nil,
            consumedCount: 900,
            consumedTotal: 1_000,
            consumedPercent: 0.9
        )

        let presentation = try XCTUnwrap(
            ReadingProgressPresentation(singleFileProgress: progress)
        )

        XCTAssertEqual(presentation.percent, 90)
        XCTAssertEqual(presentation.positionLabel, "Current · 5:00 of 16:40")
    }
}
