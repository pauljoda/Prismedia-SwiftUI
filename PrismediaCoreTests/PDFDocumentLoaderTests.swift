import PDFKit
import XCTest

@testable import PrismediaCore

@MainActor
final class PDFDocumentLoaderTests: XCTestCase {
    func testLoadsAValidDocumentWithPages() throws {
        let source = PDFDocument()
        source.insert(PDFPage(), at: 0)
        source.insert(PDFPage(), at: 1)
        let data = try XCTUnwrap(source.dataRepresentation())

        let loaded = try PDFDocumentLoader().load(data: data)

        XCTAssertEqual(loaded.pageCount, 2)
    }

    func testRejectsInvalidAndEmptyDocuments() {
        XCTAssertThrowsError(try PDFDocumentLoader().load(data: Data("not a pdf".utf8))) { error in
            XCTAssertEqual(error as? PDFReaderError, .invalidDocument)
        }

        let emptyData = PDFDocument().dataRepresentation() ?? Data()
        XCTAssertThrowsError(try PDFDocumentLoader().load(data: emptyData)) { error in
            XCTAssertEqual(error as? PDFReaderError, .invalidDocument)
        }
    }
}
