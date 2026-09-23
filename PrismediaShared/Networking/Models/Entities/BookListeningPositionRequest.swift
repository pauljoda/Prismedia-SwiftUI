import Foundation

/// Physical audiobook coordinate paired with a Book progress report.
public struct BookListeningPositionRequest: Encodable, Hashable, Sendable {
    public let trackEntityID: UUID
    public let markerID: UUID?
    public let offsetSeconds: Double

    private enum CodingKeys: String, CodingKey {
        case trackEntityID = "trackEntityId"
        case markerID = "markerId"
        case offsetSeconds
    }

    public init(trackEntityID: UUID, markerID: UUID?, offsetSeconds: Double) {
        self.trackEntityID = trackEntityID
        self.markerID = markerID
        self.offsetSeconds = offsetSeconds
    }
}
