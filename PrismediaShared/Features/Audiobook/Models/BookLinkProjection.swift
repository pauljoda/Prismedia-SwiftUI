import Foundation

/// How a Book's reading and listening relate, from the server's alignment (`link`): Linked when its
/// audio has exact chapter boundaries and at least one chapter pair comes from exact evidence,
/// Separate otherwise, with each format's own progress. Servers that predate the decision omit it.
public struct BookLinkProjection: Equatable, Hashable, Sendable {
    // MARK: - Variables

    public let state: BookLinkState
    /// Why the Book is Separate; nil when Linked.
    public let reason: BookAlignmentGapReason?
    /// How the audio divides into chapters, or nil without playable audio.
    public let audioStructure: AudiobookStructure?
    /// Share (0...1) of the readable rendition before the reading position, when there is one.
    public let readingFraction: Double?
    /// Share (0...1) of the known audio listened before the listening position, when there is one.
    public let listeningFraction: Double?

    /// Whether reading and listening are tracked apart. Only an explicit Separate decision counts, so
    /// an unknown future state keeps today's linked behavior.
    public var isSeparate: Bool {
        state == .separate
    }

    /// The two progresses a Separate Book shows instead of one; nil when Linked.
    public var separateProgress: EntitySeparateProgress? {
        guard isSeparate else { return nil }
        return EntitySeparateProgress(
            reason: reason,
            readingFraction: readingFraction,
            listeningFraction: listeningFraction
        )
    }

    // MARK: - Initializers

    public init(
        state: BookLinkState,
        reason: BookAlignmentGapReason? = nil,
        audioStructure: AudiobookStructure? = nil,
        readingFraction: Double? = nil,
        listeningFraction: Double? = nil
    ) {
        self.state = state
        self.reason = reason
        self.audioStructure = audioStructure
        self.readingFraction = readingFraction
        self.listeningFraction = listeningFraction
    }
}

extension BookLinkProjection: Decodable {
    private enum CodingKeys: String, CodingKey {
        case state, reason, audioStructure
        case readingFraction = "readingPercent"
        case listeningFraction = "listeningPercent"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        state = try container.decode(BookLinkState.self, forKey: .state)
        reason = try container.decodeIfPresent(BookAlignmentGapReason.self, forKey: .reason)
        audioStructure = try container.decodeIfPresent(AudiobookStructure.self, forKey: .audioStructure)
        readingFraction = try container.decodeFlexibleDoubleIfPresent(forKey: .readingFraction)
        listeningFraction = try container.decodeFlexibleDoubleIfPresent(forKey: .listeningFraction)
    }
}
