import Foundation

public enum ReleaseCalendarDatePolicy {
    public static let visibleDayEventLimit = 3

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

    public static func gridInterval(containing date: Date, calendar: Calendar = .current) -> DateInterval? {
        let days = gridDays(containing: date, calendar: calendar)
        guard let first = days.first, let last = days.last else { return nil }
        return DateInterval(start: first, end: last)
    }
}
