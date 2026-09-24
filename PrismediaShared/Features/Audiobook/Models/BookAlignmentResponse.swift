import Foundation

/// Server-owned alignment between a Book's readable chapters and its audio chapter windows, with
/// the current user's exact positions and the resume, switch, and combined destinations derived
/// from them (`GET /api/books/{id}/alignment`, and the response of a chapter-mapping save).
/// The native app opens the returned targets verbatim and never aligns positions itself.
public struct BookAlignmentResponse: Equatable, Hashable, Sendable {
    // MARK: - Variables

    /// Consumption modalities the Book has content for.
    public let modalities: [ConsumptionModality]
    /// Total that whole-book EPUB reading positions are expressed in; reading reports for a
    /// `cfi` position must use it as their total.
    public let readablePositionTotal: Int
    /// Alignment rows in display order.
    public let rows: [BookAlignmentRow]
    public let coverage: BookAlignmentCoverage
    /// The current user's resume destinations, when the Book has content to resume.
    public let resume: BookResumeProjection?

    /// Whether the Book can be read and listened to together.
    var supportsReadingAndListening: Bool {
        modalities.contains(.reading) && modalities.contains(.listening)
    }

    /// Readable chapter windows in display order.
    var readableWindows: [BookReadableChapterWindow] {
        rows.compactMap(\.readable)
    }

    /// Paired rows as persisted chapter mappings, with their provenance.
    var chapterMappings: [BookChapterAudioMapping] {
        rows.compactMap(\.chapterMapping)
    }

    // MARK: - Initializers

    public init(
        modalities: [ConsumptionModality],
        readablePositionTotal: Int,
        rows: [BookAlignmentRow],
        coverage: BookAlignmentCoverage = BookAlignmentCoverage(),
        resume: BookResumeProjection? = nil
    ) {
        self.modalities = modalities
        self.readablePositionTotal = readablePositionTotal
        self.rows = rows
        self.coverage = coverage
        self.resume = resume
    }
}

extension BookAlignmentResponse: Decodable {
    private enum CodingKeys: String, CodingKey {
        case modalities, readablePositionTotal, rows, coverage, resume
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        modalities = try container.decodeIfPresent([ConsumptionModality].self, forKey: .modalities) ?? []
        readablePositionTotal = try container.decodeFlexibleInt(forKey: .readablePositionTotal)
        rows = try container.decodeIfPresent([BookAlignmentRow].self, forKey: .rows) ?? []
        coverage =
            try container.decodeIfPresent(BookAlignmentCoverage.self, forKey: .coverage)
            ?? BookAlignmentCoverage()
        resume = try container.decodeIfPresent(BookResumeProjection.self, forKey: .resume)
    }
}
