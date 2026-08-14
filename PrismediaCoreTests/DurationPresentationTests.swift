import Foundation
import XCTest

@testable import PrismediaCore

final class DurationPresentationTests: XCTestCase {
    private let locale = Locale(identifier: "en_US")

    func testActivityDurationUsesNamedUnitsAndRollsHoursIntoDays() {
        XCTAssertEqual(DurationPresentation.activity(3, locale: locale), "3s")
        XCTAssertEqual(DurationPresentation.activity(37_802, locale: locale), "10h 30m")
        XCTAssertEqual(DurationPresentation.activity(84_388, locale: locale), "23h 26m")
        XCTAssertEqual(DurationPresentation.activity(354_373, locale: locale), "4d 2h")
    }

    func testProgressDurationUsesReadableMediaUnits() {
        XCTAssertEqual(DurationPresentation.progress(300, locale: locale), "5 min")
        XCTAssertEqual(DurationPresentation.progress(1_000, locale: locale), "16 min, 40 sec")
        XCTAssertEqual(DurationPresentation.progress(8_203, locale: locale), "2 hr, 17 min")
    }

    func testInvalidDurationsFallBackToZero() {
        XCTAssertEqual(DurationPresentation.activity(.nan, locale: locale), "0s")
        XCTAssertEqual(DurationPresentation.progress(-1, locale: locale), "0 sec")
    }
}
