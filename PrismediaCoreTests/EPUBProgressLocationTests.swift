import XCTest

@testable import PrismediaCore

final class EPUBProgressLocationTests: XCTestCase {
    func testReadiumLocatorExposesChapterAndBothProgressFractions() throws {
        let serialized = """
            {"href":"Text/chapter-4.xhtml","type":"application/xhtml+xml",\
            "locations":{"progression":0.5,"totalProgression":0.42}}
            """
        let location = try XCTUnwrap(
            EPUBProgressLocation(serialized: serialized)
        )

        XCTAssertEqual(location.href, "Text/chapter-4.xhtml")
        XCTAssertEqual(location.resourceProgression, 0.5, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(location.totalProgression), 0.42, accuracy: 0.001)
    }

    func testFallbackProgressMarkerExposesChapterAndLocalFraction() throws {
        let location = try XCTUnwrap(
            EPUBProgressLocation(
                serialized: "Text/chapter-2.xhtml#prismedia-progress=0.25"
            )
        )

        XCTAssertEqual(location.href, "Text/chapter-2.xhtml")
        XCTAssertEqual(location.resourceProgression, 0.25, accuracy: 0.001)
        XCTAssertNil(location.totalProgression)
    }

    func testMalformedOrCFILocationsDoNotPretendToIdentifyAChapter() {
        XCTAssertNil(EPUBProgressLocation(serialized: "epubcfi(/6/4!/4/2)"))
        XCTAssertNil(EPUBProgressLocation(serialized: "not json{"))
    }
}
