import XCTest

@testable import PrismediaCore

final class PDFReaderLayoutModeTests: XCTestCase {
    func testReaderModesRoundTripThroughPDFLayoutChoices() {
        XCTAssertEqual(PDFReaderLayoutMode(readerMode: .paged), .paged)
        XCTAssertEqual(PDFReaderLayoutMode(readerMode: .scrolled), .continuous)
        XCTAssertEqual(PDFReaderLayoutMode.paged.readerMode, .paged)
        XCTAssertEqual(PDFReaderLayoutMode.continuous.readerMode, .scrolled)
    }

    func testUnknownOrMissingReaderModeUsesTheNativeContinuousDefault() {
        XCTAssertEqual(PDFReaderLayoutMode(readerMode: nil), .continuous)
        XCTAssertEqual(PDFReaderLayoutMode(readerMode: .webtoon), .continuous)
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
