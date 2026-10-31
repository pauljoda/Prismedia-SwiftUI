import Foundation

public enum ReleaseCalendarDatePolicy {
    public static let visibleDayEventLimit = 3

    public static func monthCacheKey(
        for date: Date,
        calendar: Calendar = .current
    ) -> String {
        guard let monthStart = calendar.dateInterval(of: .month, for: date)?.start else {
            return wireValue(date, calendar: calendar)
        }
        return wireValue(monthStart, calendar: calendar)
    }

    public static func preloadMonths(
        around date: Date,
        calendar: Calendar = .current
    ) -> [Date] {
        guard let monthStart = calendar.dateInterval(of: .month, for: date)?.start else {
            return [date]
        }
        return (-1...1).compactMap {
            calendar.date(byAdding: .month, value: $0, to: monthStart)
        }
    }

    public static func wireValue(_ date: Date, calendar: Calendar = .current) -> String {
        let values = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", values.year ?? 0, values.month ?? 0, values.day ?? 0)
    }

    public static func date(from wireValue: String, calendar: Calendar = .current) -> Date? {
        let parts = wireValue.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }

    public static func monthInterval(containing date: Date, calendar: Calendar = .current) -> DateInterval? {
        guard let month = calendar.dateInterval(of: .month, for: date),
            let finalDay = calendar.date(byAdding: .day, value: -1, to: month.end)
        else { return nil }
        return DateInterval(start: month.start, end: finalDay)
    }

    public static func gridDays(containing date: Date, calendar: Calendar = .current) -> [Date] {
        guard let month = monthInterval(containing: date, calendar: calendar) else { return [] }
        let firstWeekday = calendar.component(.weekday, from: month.start)
        let leading = (firstWeekday - calendar.firstWeekday + 7) % 7
        guard let gridStart = calendar.date(byAdding: .day, value: -leading, to: month.start) else { return [] }
        return (0..<42).compactMap { calendar.date(byAdding: .day, value: $0, to: gridStart) }
    }

    /// The day the two-pane calendar lists beside the month. A day the person
    /// picked stays while it is on the month's grid. Otherwise the month that
    /// holds today shows the next day with releases from today, or today; any
    /// other month shows its first day with releases, or its first day.
    public static func focusedDay(
        selected: Date?,
        in month: Date,
        today: Date,
        releaseDays: [Date],
        calendar: Calendar = .current
    ) -> Date {
        let gridDays = gridDays(containing: month, calendar: calendar)
        if let selected, gridDays.contains(calendar.startOfDay(for: selected)) {
            return calendar.startOfDay(for: selected)
        }
        guard let monthDays = monthInterval(containing: month, calendar: calendar) else {
            return calendar.startOfDay(for: month)
        }
        let releaseDaysInMonth = releaseDays
            .map { calendar.startOfDay(for: $0) }
            .filter { $0 >= monthDays.start && $0 <= monthDays.end }
            .sorted()
        let startOfToday = calendar.startOfDay(for: today)
        if startOfToday >= monthDays.start && startOfToday <= monthDays.end {
            return releaseDaysInMonth.first { $0 >= startOfToday } ?? startOfToday
        }
        return releaseDaysInMonth.first ?? monthDays.start
    }

    public static func gridInterval(containing date: Date, calendar: Calendar = .current) -> DateInterval? {
        let days = gridDays(containing: date, calendar: calendar)
        guard let first = days.first, let last = days.last else { return nil }
        return DateInterval(start: first, end: last)
    }
}
