import Foundation

/// One persisted pairing of a readable chapter with an audio chapter window of the same Book.
public struct BookChapterAudioMapping: Codable, Equatable, Hashable, Sendable {
    // MARK: - Variables

    public let readableChapterKey: String
    public let audioTrackID: UUID
    public let audioMarkerID: UUID?

    /// Mapping provenance: `manual` (picked by hand), `ordered` (filled in playback order and
    /// reviewed), or `auto` (the server's exact-title matcher). Absent on responses from servers that
    /// predate persisted automatic matching, which means manual.
    public let origin: BookChapterMappingOrigin?

    /// Whether the server derived this pair automatically. Automatic rows render like any other
    /// mapping but must never be echoed back in a save request — the server rejects them, and
    /// they refresh on their own when files or tracks change.
    public var isAutomatic: Bool { origin == .auto }

    /// The audio chapter this pair names, in the same form as ``BookAudioChapter/identity``.
    var audioChapterIdentity: String {
        "\(audioTrackID.uuidString):\(audioMarkerID?.uuidString ?? "whole")"
    }

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

    // MARK: - Actions - Provenance

    /// This pair as confirmed by a person through `origin` (`manual` or `ordered`).
    func confirmed(_ origin: BookChapterMappingOrigin) -> Self {
        Self(
            readableChapterKey: readableChapterKey,
            audioTrackID: audioTrackID,
            origin: origin,
            audioMarkerID: audioMarkerID
        )
    }

    private enum CodingKeys: String, CodingKey {
        case readableChapterKey
        case audioTrackID = "audioTrackId"
        case audioMarkerID = "audioMarkerId"
        case origin
    }
}
