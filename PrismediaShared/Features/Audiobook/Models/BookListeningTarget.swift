import Foundation

/// A server-chosen position on a Book's physical audio track.
public struct BookListeningTarget: Equatable, Hashable, Sendable {
    // MARK: - Variables

    public let trackEntityID: UUID
    public let markerID: UUID?
    public let offsetSeconds: Double

    /// The player start point for this target.
    var resumePoint: AudiobookResumePoint {
        AudiobookResumePoint(trackID: trackEntityID, trackOffsetSeconds: max(0, offsetSeconds))
    }

    // MARK: - Initializers

    public init(trackEntityID: UUID, markerID: UUID? = nil, offsetSeconds: Double) {
        self.trackEntityID = trackEntityID
        self.markerID = markerID
        self.offsetSeconds = offsetSeconds
    }
}

extension BookListeningTarget: Decodable {
    private enum CodingKeys: String, CodingKey {
        case trackEntityID = "trackEntityId"
        case markerID = "markerId"
        case offsetSeconds
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        trackEntityID = try container.decode(UUID.self, forKey: .trackEntityID)
        markerID = try container.decodeIfPresent(UUID.self, forKey: .markerID)
        offsetSeconds = try container.decodeFlexibleDouble(forKey: .offsetSeconds)
    }
}
