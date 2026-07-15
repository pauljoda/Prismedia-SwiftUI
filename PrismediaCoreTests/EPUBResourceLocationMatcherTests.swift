import XCTest

@testable import PrismediaCore

final class EPUBResourceLocationMatcherTests: XCTestCase {
    func testMatchesPackagePrefixedReadiumLocation() {
        let match = EPUBResourceLocationMatcher().bestMatch(
            for: "Text/chapter-7.xhtml#opening",
            candidates: ["OEBPS/Text/chapter-6.xhtml", "OEBPS/Text/chapter-7.xhtml#opening"]
        )

        XCTAssertEqual(match, "OEBPS/Text/chapter-7.xhtml#opening")
    }

    func testMatchesDecodedAndNormalizedResource() {
        let match = EPUBResourceLocationMatcher().bestMatch(
            for: "Text\\Chapter%2007.xhtml#Start",
            candidates: ["Text/Chapter 07.xhtml#start"]
        )

        XCTAssertEqual(match, "Text/Chapter 07.xhtml#start")
    }

    func testDoesNotGuessBetweenDuplicateFileNames() {
        let match = EPUBResourceLocationMatcher().bestMatch(
            for: "chapter.xhtml",
            candidates: ["PartOne/chapter.xhtml", "PartTwo/chapter.xhtml"]
        )

        XCTAssertNil(match)
    }
}
