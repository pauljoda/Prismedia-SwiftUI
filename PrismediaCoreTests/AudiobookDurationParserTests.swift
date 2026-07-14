import XCTest

@testable import PrismediaCore

final class AudiobookDurationParserTests: XCTestCase {
    func testSupportedTechnicalDurationsPreserveFullPrecision() {
        XCTAssertEqual(AudiobookDurationParser.seconds(from: "10:05:00"), 36_300)
        XCTAssertEqual(AudiobookDurationParser.seconds(from: "1.02:03:04"), 93_784)
        XCTAssertEqual(AudiobookDurationParser.seconds(from: "00:01:40.5000000"), 100.5)
    }

    func testInvalidDurationDoesNotFabricateProgress() {
        XCTAssertNil(AudiobookDurationParser.seconds(from: "unknown"))
    }
}
