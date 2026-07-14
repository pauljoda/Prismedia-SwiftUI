import XCTest

@testable import PrismediaCore

final class AudiobookDurationParserTests: XCTestCase {
    func testFullTechnicalDurationPreservesTenHourAudiobookPart() {
        XCTAssertEqual(AudiobookDurationParser.seconds(from: "10:05:00"), 36_300)
    }

    func testDotNetDayPrefixIsIncludedInDuration() {
        XCTAssertEqual(AudiobookDurationParser.seconds(from: "1.02:03:04"), 93_784)
    }

    func testDotNetFractionalSecondsArePreserved() {
        XCTAssertEqual(AudiobookDurationParser.seconds(from: "00:01:40.5000000"), 100.5)
    }

    func testInvalidDurationDoesNotFabricateProgress() {
        XCTAssertNil(AudiobookDurationParser.seconds(from: "unknown"))
    }
}
