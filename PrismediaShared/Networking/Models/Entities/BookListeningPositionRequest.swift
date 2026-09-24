import Foundation

/// Exact physical audiobook position reported for a Book: the track, the chapter marker when the
/// client knows it, and the offset from the start of the track.
public struct BookListeningPositionRequest: Encodable, Hashable, Sendable {
    // MARK: - Variables

    public let trackEntityID: UUID
    /// Chapter marker inside the track; the server locates the window from the offset when nil.
    public let markerID: UUID?
    public let offsetSeconds: Double

    // MARK: - Initializers

    public init(trackEntityID: UUID, markerID: UUID?, offsetSeconds: Double) {
        self.trackEntityID = trackEntityID
        self.markerID = markerID
        self.offsetSeconds = offsetSeconds
    }

    private enum CodingKeys: String, CodingKey {
        case trackEntityID = "trackEntityId"
        case markerID = "markerId"
        case offsetSeconds
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(trackEntityID, forKey: .trackEntityID)
        try container.encode(markerID, forKey: .markerID)
        try container.encode(offsetSeconds, forKey: .offsetSeconds)
    }
}
