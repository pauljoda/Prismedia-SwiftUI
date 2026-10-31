import XCTest

@testable import PrismediaCore

final class PDFReaderLayoutModeTests: XCTestCase {
    func testReaderModesRoundTripAndUnknownModesUseTheContinuousDefault() {
        XCTAssertEqual(PDFReaderLayoutMode(readerMode: .paged), .paged)
        XCTAssertEqual(PDFReaderLayoutMode(readerMode: .scrolled), .continuous)
        XCTAssertEqual(PDFReaderLayoutMode.paged.readerMode, .paged)
        XCTAssertEqual(PDFReaderLayoutMode.continuous.readerMode, .scrolled)
        XCTAssertEqual(PDFReaderLayoutMode(readerMode: nil), .continuous)
        XCTAssertEqual(PDFReaderLayoutMode(readerMode: .webtoon), .continuous)
    }

    func testSpreadsPairPagesFromTheFirstAndPageBySpread() {
        XCTAssertEqual(PDFReaderSpread.firstPage(showing: 0), 0)
        XCTAssertEqual(PDFReaderSpread.firstPage(showing: 1), 0)
        XCTAssertEqual(PDFReaderSpread.firstPage(showing: 3), 2)

        XCTAssertEqual(PDFReaderSpread.nextPage(from: 1, pageCount: 5), 2)
        XCTAssertEqual(PDFReaderSpread.nextPage(from: 3, pageCount: 5), 4)
        XCTAssertEqual(PDFReaderSpread.nextPage(from: 4, pageCount: 5), 4)
        XCTAssertFalse(PDFReaderSpread.hasNextPage(from: 4, pageCount: 5))
        XCTAssertFalse(PDFReaderSpread.hasNextPage(from: 0, pageCount: 2))
        XCTAssertTrue(PDFReaderSpread.hasNextPage(from: 3, pageCount: 5))

        XCTAssertEqual(PDFReaderSpread.previousPage(from: 3), 0)
        XCTAssertEqual(PDFReaderSpread.previousPage(from: 1), 0)
        XCTAssertEqual(PDFReaderSpread.previousPage(from: 4), 2)
    }

    func testProgressRequestPersistsTheSelectedPDFReaderMode() {
        let bookID = UUID()

        for mode in PDFReaderLayoutMode.allCases {
            let request = DocumentReaderProgressMapper.request(
                bookID: bookID,
                index: 1,
                total: 3,
                unit: .page,
                mode: mode.readerMode,
                location: nil
            )

            XCTAssertEqual(request.mode, mode.readerMode)
        }
    }
}
