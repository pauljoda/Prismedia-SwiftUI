import Foundation
import XCTest

@testable import PrismediaCore

final class CalendarDayPresentationTests: XCTestCase {
    private let locale = Locale(identifier: "en_US")
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Chicago")!
        return calendar
    }

    func testCalendarDayUsesRelativeLabelsForRecentDates() {
        let now = Date(timeIntervalSince1970: 1_786_723_200)  // 2026-08-14 11:00:00 CDT

        XCTAssertEqual(
            CalendarDayPresentation.label(
                for: "2026-08-14", relativeTo: now, calendar: calendar, locale: locale),
            "Today"
        )
        XCTAssertEqual(
            CalendarDayPresentation.label(
                for: "2026-08-13", relativeTo: now, calendar: calendar, locale: locale),
            "Yesterday"
        )
    }

    func testCalendarDayUsesReadableLocalizedDates() {
        let now = Date(timeIntervalSince1970: 1_786_723_200)

        XCTAssertEqual(
            CalendarDayPresentation.label(
                for: "2026-07-31", relativeTo: now, calendar: calendar, locale: locale),
            "Jul 31"
        )
        XCTAssertEqual(
            CalendarDayPresentation.label(
                for: "2025-07-31", relativeTo: now, calendar: calendar, locale: locale),
            "Jul 31, 2025"
        )
    }

    func testCalendarDayPreservesAnUnrecognizedServerValue() {
        XCTAssertEqual(
            CalendarDayPresentation.label(
                for: "not-a-day", relativeTo: Date(), calendar: calendar, locale: locale),
            "not-a-day"
        )
    }
}
