import CoreGraphics
import CoreText
import Foundation
import PDFKit
import XCTest

@testable import PrismediaCore

@MainActor
final class PDFTextSearchServiceTests: XCTestCase {
    func testFindsCaseAndDiacriticInsensitiveTextSelections() async throws {
        let document = try makeSearchableDocument(text: "Signal signal café")

        let signalMatches = await PDFTextSearchService().matches(in: document, query: "SIGNAL")
        let cafeMatches = await PDFTextSearchService().matches(in: document, query: "cafe")

        XCTAssertEqual(signalMatches.count, 2)
        XCTAssertEqual(cafeMatches.count, 1)
        XCTAssertTrue(signalMatches.allSatisfy { $0.pages.first === document.page(at: 0) })
    }

    func testWhitespaceOnlyQueryReturnsNoSelections() async throws {
        let document = try makeSearchableDocument(text: "Signal")

        let matches = await PDFTextSearchService().matches(in: document, query: "   ")

        XCTAssertTrue(matches.isEmpty)
    }

    private func makeSearchableDocument(text: String) throws -> PDFDocument {
        let data = NSMutableData()
        let consumer = try XCTUnwrap(CGDataConsumer(data: data))
        var mediaBox = CGRect(x: 0, y: 0, width: 612, height: 792)
        let context = try XCTUnwrap(CGContext(consumer: consumer, mediaBox: &mediaBox, nil))
        context.beginPDFPage(nil)
        let attributedText = NSAttributedString(
            string: text,
            attributes: [
                NSAttributedString.Key(kCTFontAttributeName as String):
                    CTFontCreateWithName("Helvetica" as CFString, 18, nil)
            ]
        )
        context.textPosition = CGPoint(x: 72, y: 700)
        CTLineDraw(CTLineCreateWithAttributedString(attributedText), context)
        context.endPDFPage()
        context.closePDF()
        return try XCTUnwrap(PDFDocument(data: data as Data))
    }
}
