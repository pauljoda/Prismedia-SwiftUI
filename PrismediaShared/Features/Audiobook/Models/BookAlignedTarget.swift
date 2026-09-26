import Foundation

/// A server-aligned destination: one or both sides of a Book alignment row, how it was derived,
/// or the gap that prevented alignment. The server never substitutes another chapter for a gap.
public struct BookAlignedTarget: Equatable, Hashable, Sendable {
    // MARK: - Variables

    /// Alignment row that holds the target, or the row where the gap happened.
    public let rowID: String?
    public let reading: BookReadingTarget?
    public let listening: BookListeningTarget?
    /// Whether the target was estimated from the other modality rather than recorded.
    public let approximate: Bool
    public let basis: BookAlignmentBasis
    public let gap: BookAlignmentGapReason?
    public let gapChapterTitle: String?

    /// The target itself when the server aligned it, or nil when it reported a gap.
    var aligned: Self? {
        gap == nil ? self : nil
    }

    /// Why the target could not be aligned, in user-facing words.
    var gapExplanation: String? {
        gap.flatMap(BookAlignmentGapExplanation.explaining)?.text(chapterTitle: gapChapterTitle)
    }

    // MARK: - Initializers

    public init(
        rowID: String? = nil,
        reading: BookReadingTarget? = nil,
        listening: BookListeningTarget? = nil,
        approximate: Bool = false,
        basis: BookAlignmentBasis = .exact,
        gap: BookAlignmentGapReason? = nil,
        gapChapterTitle: String? = nil
    ) {
        self.rowID = rowID
        self.reading = reading
        self.listening = listening
        self.approximate = approximate
        self.basis = basis
        self.gap = gap
        self.gapChapterTitle = gapChapterTitle
    }
}

extension BookAlignedTarget: Decodable {
    private enum CodingKeys: String, CodingKey {
        case rowID = "rowId"
        case reading, listening, approximate, basis, gap, gapChapterTitle
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        rowID = try container.decodeIfPresent(String.self, forKey: .rowID)
        reading = try container.decodeIfPresent(BookReadingTarget.self, forKey: .reading)
        listening = try container.decodeIfPresent(BookListeningTarget.self, forKey: .listening)
        approximate = try container.decodeIfPresent(Bool.self, forKey: .approximate) ?? false
        basis = try container.decode(BookAlignmentBasis.self, forKey: .basis)
        gap = try container.decodeIfPresent(BookAlignmentGapReason.self, forKey: .gap)
        gapChapterTitle = try container.decodeIfPresent(String.self, forKey: .gapChapterTitle)
    }
}
