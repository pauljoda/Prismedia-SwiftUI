import Foundation

struct ReleaseCalendarDaySelection: Identifiable, Hashable, Sendable {
    let date: Date
    let events: [ReleaseCalendarEvent]

    var id: Date { date }
}
