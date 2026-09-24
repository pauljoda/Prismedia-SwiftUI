import Foundation

/// One persisted pairing of a readable chapter with an audio chapter window of the same Book.
public struct BookChapterAudioMapping: Codable, Equatable, Hashable, Sendable {
    // MARK: - Variables

    public let readableChapterKey: String
    public let audioTrackID: UUID
    public let audioMarkerID: UUID?

    /// Mapping provenance. Absent on saves and on responses from servers that predate persisted
    /// automatic matching, both of which mean manual.
    public let origin: BookChapterMappingOrigin?

    /// Whether the server derived this pair automatically. Automatic rows render like any other
    /// mapping but must never be echoed back in a save request — the server would then treat
    /// them as user choices and stop refreshing them when files or tracks change.
    public var isAutomatic: Bool { origin == .auto }

    // MARK: - Initializers

    public init(
        readableChapterKey: String,
        audioTrackID: UUID,
        origin: BookChapterMappingOrigin? = nil,
        audioMarkerID: UUID? = nil
    ) {
        self.readableChapterKey = readableChapterKey
        self.audioTrackID = audioTrackID
        self.origin = origin
        self.audioMarkerID = audioMarkerID
    }

    private enum CodingKeys: String, CodingKey {
        case readableChapterKey
        case audioTrackID = "audioTrackId"
        case audioMarkerID = "audioMarkerId"
        case origin
    }
}
