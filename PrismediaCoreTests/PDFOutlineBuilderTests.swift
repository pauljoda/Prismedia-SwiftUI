import PDFKit
import XCTest

@testable import PrismediaCore

@MainActor
final class PDFOutlineBuilderTests: XCTestCase {
    func testBuildsNestedTableOfContentsWithPageDestinations() throws {
        let document = PDFDocument()
        let firstPage = PDFPage()
        let secondPage = PDFPage()
        document.insert(firstPage, at: 0)
        document.insert(secondPage, at: 1)

        let root = PDFOutline()
        let chapter = PDFOutline()
        chapter.label = "Chapter One"
        chapter.destination = PDFDestination(page: firstPage, at: .zero)
        let section = PDFOutline()
        section.label = "Section A"
        section.destination = PDFDestination(page: secondPage, at: .zero)
        chapter.insertChild(section, at: 0)
        root.insertChild(chapter, at: 0)
        document.outlineRoot = root

        let items = PDFOutlineBuilder().items(in: document)

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].title, "Chapter One")
        XCTAssertEqual(items[0].pageIndex, 0)
        XCTAssertEqual(items[0].children?.first?.title, "Section A")
        XCTAssertEqual(items[0].children?.first?.pageIndex, 1)
    }

    func testMissingOutlineAndBlankLabelsRemainSafe() throws {
        let document = PDFDocument()
        let page = PDFPage()
        document.insert(page, at: 0)

        XCTAssertEqual(PDFOutlineBuilder().items(in: document), [])

        let root = PDFOutline()
        let blank = PDFOutline()
        blank.label = "   "
        blank.destination = PDFDestination(page: page, at: .zero)
        root.insertChild(blank, at: 0)
        document.outlineRoot = root

        XCTAssertEqual(PDFOutlineBuilder().items(in: document).first?.title, "Untitled Section")
    }
}
