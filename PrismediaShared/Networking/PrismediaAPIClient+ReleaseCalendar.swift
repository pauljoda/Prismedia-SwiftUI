import Foundation

extension PrismediaAPIClient {
    public func releaseCalendar(
        from start: Date,
        through end: Date,
        calendar: Calendar = .current
    ) async throws -> [ReleaseCalendarEvent] {
        try await send(
            [ReleaseCalendarEvent].self,
            path: "/api/calendar/releases",
            queryItems: [
                URLQueryItem(name: "start", value: ReleaseCalendarDatePolicy.wireValue(start, calendar: calendar)),
                URLQueryItem(name: "end", value: ReleaseCalendarDatePolicy.wireValue(end, calendar: calendar)),
            ]
        )
    }
}
