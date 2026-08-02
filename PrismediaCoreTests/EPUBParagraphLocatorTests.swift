import XCTest
@testable import PrismediaCore

final class EPUBParagraphLocatorTests: XCTestCase {
    func testSemanticParagraphAnchorRoundTripsWithoutLosingReadiumProgression() throws {
        let locator =
            #"{"href":"OEBPS/chapter-1.xhtml","locations":{"progression":0.42,"totalProgression":0.21}}"#
        let anchor = EPUBParagraphAnchor(index: 17, text: "The exact paragraph in focus.")

        let enriched = try XCTUnwrap(EPUBParagraphLocator.enriching(locator, with: anchor))

        XCTAssertEqual(anchor, EPUBParagraphLocator.anchor(from: enriched))
        XCTAssertEqual("OEBPS/chapter-1.xhtml", EPUBParagraphLocator.href(from: enriched))
        let object = try XCTUnwrap(jsonObject(enriched))
        let locations = try XCTUnwrap(object["locations"] as? [String: Any])
        XCTAssertEqual(0.42, locations["progression"] as? Double)
        let text = try XCTUnwrap(object["text"] as? [String: Any])
        XCTAssertEqual("The exact paragraph in focus.", text["highlight"] as? String)
    }

    func testRemovingSemanticAnchorKeepsOtherReadiumFragments() throws {
        let locator =
            #"{"href":"chapter.xhtml","locations":{"fragments":["epubcfi(/6/2)","prismedia-paragraph=9"],"progression":0.3},"text":{"highlight":"Nine"}}"#

        let stripped = try XCTUnwrap(EPUBParagraphLocator.removingAnchor(from: locator))

        XCTAssertNil(EPUBParagraphLocator.anchor(from: stripped))
        let object = try XCTUnwrap(jsonObject(stripped))
        let locations = try XCTUnwrap(object["locations"] as? [String: Any])
        XCTAssertEqual(["epubcfi(/6/2)"], locations["fragments"] as? [String])
    }

    func testCreatesPortableSemanticLocatorForNativeFallbackReader() throws {
        let anchor = EPUBParagraphAnchor(index: 4, text: "A stable paragraph.")

        let locator = try XCTUnwrap(
            EPUBParagraphLocator.serialized(
                href: "OEBPS/chapter-2.xhtml",
                progression: 0.625,
                anchor: anchor
            )
        )

        XCTAssertEqual(anchor, EPUBParagraphLocator.anchor(from: locator))
        let progress = try XCTUnwrap(EPUBProgressLocation(serialized: locator))
        XCTAssertEqual("OEBPS/chapter-2.xhtml", progress.href)
        XCTAssertEqual(0.625, progress.resourceProgression)
        XCTAssertTrue(progress.isSerializedLocator)
    }

    private func jsonObject(_ value: String) -> [String: Any]? {
        guard let data = value.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }
}
