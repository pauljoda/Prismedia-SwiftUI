import Foundation

/// One server alignment row in display order: a readable chapter, an audio chapter window, or a
/// pair of both. Audio-only rows sit where their gap happens in the Book.
public struct BookAlignmentRow: Equatable, Hashable, Identifiable, Sendable {
    // MARK: - Variables

    /// Stable row identifier within the Book.
    public let id: String
    public let order: Int
    public let matchState: BookAlignmentMatchState
    /// Whether the user or the server's matcher paired the row, for paired rows.
    public let provenance: BookChapterMappingOrigin?
    public let readable: BookReadableChapterWindow?
    public let audio: BookAudioChapterWindow?

    /// The persisted chapter mapping this row represents, when it pairs both sides.
    var chapterMapping: BookChapterAudioMapping? {
        guard let readable, let audio else { return nil }
        return BookChapterAudioMapping(
            readableChapterKey: readable.chapterKey,
            audioTrackID: audio.trackEntityID,
            origin: provenance,
            audioMarkerID: audio.markerID
        )
    }

    // MARK: - Initializers

    public init(
        id: String,
        order: Int,
        matchState: BookAlignmentMatchState,
        provenance: BookChapterMappingOrigin? = nil,
        readable: BookReadableChapterWindow? = nil,
        audio: BookAudioChapterWindow? = nil
    ) {
        self.id = id
        self.order = order
        self.matchState = matchState
        self.provenance = provenance
        self.readable = readable
        self.audio = audio
    }
}

extension BookAlignmentRow: Decodable {
    private enum CodingKeys: String, CodingKey {
        case id = "rowId"
        case order, matchState, provenance, readable, audio
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        order = try container.decodeFlexibleIntIfPresent(forKey: .order) ?? 0
        matchState = try container.decode(BookAlignmentMatchState.self, forKey: .matchState)
        provenance = try container.decodeIfPresent(BookChapterMappingOrigin.self, forKey: .provenance)
        readable = try container.decodeIfPresent(BookReadableChapterWindow.self, forKey: .readable)
        audio = try container.decodeIfPresent(BookAudioChapterWindow.self, forKey: .audio)
    }
}
