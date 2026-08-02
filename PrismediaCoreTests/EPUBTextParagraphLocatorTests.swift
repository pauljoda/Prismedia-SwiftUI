import XCTest
@testable import PrismediaCore

final class EPUBTextParagraphLocatorTests: XCTestCase {
    func testResolvesSameParagraphAfterEarlierTextReflows() throws {
        let original = "Heading\n\nFirst paragraph.\nSecond paragraph that is being read.\nLast paragraph."
        let anchor = try XCTUnwrap(
            EPUBTextParagraphLocator().anchor(in: original, characterIndex: 35)
        )

        let reflowed = "Heading\nFirst paragraph.\n\nSecond paragraph that is being read.\nLast paragraph."
        let restoredIndex = try XCTUnwrap(
            EPUBTextParagraphLocator().characterIndex(for: anchor, in: reflowed)
        )

        XCTAssertEqual(
            "Second paragraph that is being read.",
            (reflowed as NSString).substring(
                with: (reflowed as NSString).paragraphRange(
                    for: NSRange(location: restoredIndex, length: 0)
                )
            ).trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    func testUsesTextFallbackWhenParagraphIndexChanges() throws {
        let anchor = EPUBParagraphAnchor(index: 1, text: "Target paragraph")
        let changed = "Inserted paragraph\nAnother inserted paragraph\nTarget paragraph\nEnding"

        let restoredIndex = try XCTUnwrap(
            EPUBTextParagraphLocator().characterIndex(for: anchor, in: changed)
        )

        XCTAssertEqual(46, restoredIndex)
    }
}
