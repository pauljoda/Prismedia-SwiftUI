import Foundation

/// The audio side of one server alignment row: a whole track, or one source-owned chapter marker
/// inside a track, with its time window.
public struct BookAudioChapterWindow: Equatable, Hashable, Sendable {
    // MARK: - Variables

    public let trackEntityID: UUID
    public let markerID: UUID?
    public let title: String
    public let startSeconds: Double
    /// End of the window; nil when the server could not bound it.
    public let endSeconds: Double?
    /// Whether the server inferred the end from the next marker or the track duration.
    public let endInferred: Bool

    /// The equivalent audio chapter used by the chapter-mapping editor and its save requests.
    var audioChapter: BookAudioChapter {
        BookAudioChapter(
            audioTrackID: trackEntityID,
            audioMarkerID: markerID,
            title: title,
            startSeconds: startSeconds,
            endSeconds: endSeconds
        )
    }

    // MARK: - Initializers

    public init(
        trackEntityID: UUID,
        markerID: UUID? = nil,
        title: String,
        startSeconds: Double = 0,
        endSeconds: Double? = nil,
        endInferred: Bool = false
    ) {
        self.trackEntityID = trackEntityID
        self.markerID = markerID
        self.title = title
        self.startSeconds = startSeconds
        self.endSeconds = endSeconds
        self.endInferred = endInferred
    }
}

extension BookAudioChapterWindow: Decodable {
    private enum CodingKeys: String, CodingKey {
        case trackEntityID = "trackEntityId"
        case markerID = "markerId"
        case title, startSeconds, endSeconds, endInferred
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        trackEntityID = try container.decode(UUID.self, forKey: .trackEntityID)
        markerID = try container.decodeIfPresent(UUID.self, forKey: .markerID)
        title = try container.decode(String.self, forKey: .title)
        startSeconds = try container.decodeFlexibleDoubleIfPresent(forKey: .startSeconds) ?? 0
        endSeconds = try container.decodeFlexibleDoubleIfPresent(forKey: .endSeconds)
        endInferred = try container.decodeIfPresent(Bool.self, forKey: .endInferred) ?? false
    }
}
