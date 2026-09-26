import Foundation

/// The two progresses of a Book that keeps reading and listening Separate: its audio has no exact
/// chapter pairing with the readable rendition, so each share comes only from its own format's
/// exact position and neither is ever shown as the other. Clients draw two meters from it instead
/// of one.
public struct EntitySeparateProgress: Equatable, Hashable, Sendable {
    // MARK: - Variables

    /// Why the Book keeps reading and listening separate. Unknown future reasons are kept as given.
    public let reason: BookAlignmentGapReason?
    /// Share (0...1) of the readable rendition before the reading position, when there is one.
    public let readingFraction: Double?
    /// Share (0...1) of the known audio listened before the listening position, when there is one.
    public let listeningFraction: Double?

    /// Whole reading percent (0...100) for a meter.
    public var readingPercent: Int {
        Self.wholePercent(readingFraction)
    }

    /// Whole listening percent (0...100) for a meter.
    public var listeningPercent: Int {
        Self.wholePercent(listeningFraction)
    }

    /// One-line, user-facing reason reading and listening are tracked separately.
    var explanation: String {
        BookAlignmentGapExplanation.separateText(for: reason)
    }

    // MARK: - Initializers

    public init(reason: BookAlignmentGapReason?, readingFraction: Double?, listeningFraction: Double?) {
        self.reason = reason
        self.readingFraction = readingFraction
        self.listeningFraction = listeningFraction
    }

    // MARK: - Actions - Presentation

    private static func wholePercent(_ fraction: Double?) -> Int {
        guard let fraction, fraction.isFinite else { return 0 }
        return Int((min(1, max(0, fraction)) * 100).rounded())
    }
}

extension EntitySeparateProgress: Decodable {
    private enum CodingKeys: String, CodingKey {
        case reason
        case readingFraction = "readingPercent"
        case listeningFraction = "listeningPercent"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        reason = try container.decodeIfPresent(BookAlignmentGapReason.self, forKey: .reason)
        readingFraction = try container.decodeFlexibleDoubleIfPresent(forKey: .readingFraction)
        listeningFraction = try container.decodeFlexibleDoubleIfPresent(forKey: .listeningFraction)
    }
}
