import Foundation

public struct PrismediaReleaseCalendarLoader: ReleaseCalendarLoading, Sendable {
    private let client: PrismediaAPIClient

    public init(client: PrismediaAPIClient) {
        self.client = client
    }

    public func releases(from start: Date, through end: Date) async throws -> [ReleaseCalendarEvent] {
        try await client.releaseCalendar(from: start, through: end)
    }
}
