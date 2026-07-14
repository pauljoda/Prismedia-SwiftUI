import XCTest

@testable import PrismediaCore

final class DocumentReaderProgressMapperTests: XCTestCase {
    func testEPUBLocationPreservesChapterAndRestoresWithinChapterProgress() {
        let location = DocumentReaderProgressMapper.epubLocation(
            chapterLocation: "Text/chapter.xhtml",
            progress: 0.425
        )

        XCTAssertEqual(DocumentReaderProgressMapper.epubBaseLocation(location), "Text/chapter.xhtml")
        XCTAssertEqual(DocumentReaderProgressMapper.epubProgress(from: location), 0.425)
    }

    private let bookID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!

    func testEPUBRestoresByLocationBeforeStaleNumericIndex() {
        let progress = EntityProgressCapability(
            currentEntityID: bookID,
            unit: .cfi,
            index: 0,
            total: 3,
            mode: .scrolled,
            completedAt: nil,
            updatedAt: nil,
            workIndex: nil,
            workTotal: nil,
            location: "Text/chapter-2.xhtml"
        )

        let index = DocumentReaderProgressMapper.initialIndex(
            progress: progress,
            locations: ["Text/chapter-1.xhtml", "Text/chapter-2.xhtml", "Text/chapter-3.xhtml"]
        )

        XCTAssertEqual(index, 1)
    }

    func testPDFProgressUsesPageContractAndCompletesOnlyOnLastPage() throws {
        let middle = DocumentReaderProgressMapper.request(
            bookID: bookID,
            index: 2,
            total: 5,
            unit: .page,
            mode: .paged,
            location: nil
        )
        let last = DocumentReaderProgressMapper.request(
            bookID: bookID,
            index: 4,
            total: 5,
            unit: .page,
            mode: .paged,
            location: nil
        )

        XCTAssertEqual(middle.currentEntityID, bookID)
        XCTAssertEqual(middle.index, 2)
        XCTAssertNil(middle.completed)
        XCTAssertEqual(last.completed, true)
    }

    func testOpeningTheLastEPUBChapterDoesNotMarkTheBookComplete() {
        let request = DocumentReaderProgressMapper.request(
            bookID: bookID,
            index: 2,
            total: 3,
            unit: .cfi,
            mode: .scrolled,
            location: "Text/chapter-3.xhtml",
            completesAtEnd: false
        )

        XCTAssertEqual(request.index, 2)
        XCTAssertNil(request.completed)
    }

    func testEPUBProgressUsesTheSharedTenThousandPointFractionContract() {
        let request = DocumentReaderProgressMapper.epubRequest(
            bookID: bookID,
            progression: 0.425,
            mode: .scrolled,
            location: "epubcfi(/6/4!/4/2/2:14)",
            closing: false
        )

        XCTAssertEqual(request.currentEntityID, bookID)
        XCTAssertEqual(request.unit, .cfi)
        XCTAssertEqual(request.index, 4_250)
        XCTAssertEqual(request.total, 10_000)
        XCTAssertEqual(request.mode, .scrolled)
        XCTAssertEqual(request.location, "epubcfi(/6/4!/4/2/2:14)")
        XCTAssertNil(request.completed)
    }

    func testClosingEPUBAtThePWAEndThresholdMarksItComplete() {
        let request = DocumentReaderProgressMapper.epubRequest(
            bookID: bookID,
            progression: 0.995,
            mode: .paged,
            location: nil,
            closing: true
        )

        XCTAssertEqual(request.completed, true)
    }

    func testOnlyFoliateCFIIsSafeForTheSharedPWAProgressLocation() {
        XCTAssertEqual(
            DocumentReaderProgressMapper.sharedEPUBLocation("epubcfi(/6/4!/4/2/2:14)"),
            "epubcfi(/6/4!/4/2/2:14)"
        )
        XCTAssertNil(
            DocumentReaderProgressMapper.sharedEPUBLocation(
                #"{"href":"Text/chapter.xhtml","type":"application/xhtml+xml"}"#
            )
        )
        XCTAssertNil(DocumentReaderProgressMapper.sharedEPUBLocation("Text/chapter.xhtml"))
    }
}
