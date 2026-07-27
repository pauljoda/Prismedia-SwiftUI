import Foundation

public protocol ReleaseCalendarLoading: Sendable {
    func releases(from start: Date, through end: Date) async throws -> [ReleaseCalendarEvent]
}
