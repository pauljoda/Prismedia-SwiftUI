import Foundation

/// User-facing labels for the local calendar-day strings returned by statistics APIs.
public enum CalendarDayPresentation {
    public static func label(
        for day: String,
        relativeTo now: Date = Date(),
        calendar: Calendar = .current,
        locale: Locale = .current
    ) -> String {
        let parser = DateFormatter()
        parser.calendar = calendar
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.timeZone = calendar.timeZone
        parser.dateFormat = "yyyy-MM-dd"

        guard let date = parser.date(from: day) else { return day }
        if calendar.isDate(date, inSameDayAs: now) { return String(localized: "Today") }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
            calendar.isDate(date, inSameDayAs: yesterday)
        {
            return String(localized: "Yesterday")
        }

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.timeZone = calendar.timeZone
        let includesYear = calendar.component(.year, from: date) != calendar.component(.year, from: now)
        formatter.setLocalizedDateFormatFromTemplate(includesYear ? "MMMdy" : "MMMd")
        return formatter.string(from: date)
    }
}
