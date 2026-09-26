import Foundation

/// A server-chosen reading position: an exact recorded checkpoint, or the reading side of an
/// aligned target. The native reader opens it verbatim and never re-aligns it.
public struct BookReadingTarget: Equatable, Hashable, Sendable {
    // MARK: - Variables

    /// The Book for whole-book EPUB/PDF positions, or the chapter Entity for paged positions.
    public let positionEntityID: UUID
    public let unit: ProgressUnit
    public let index: Int
    public let total: Int
    /// Exact opaque locator recorded by a reader, when the position is exact.
    public let location: String?
    public let chapterKey: String?
    /// Resource location of the chapter that holds the position.
    public let chapterLocation: String?
    /// Position within that chapter (0...1).
    public let chapterFraction: Double?
    /// Zero-based page within a paged chapter.
    public let pageIndex: Int?
    public let mode: ReaderMode?

    // MARK: - Initializers

    public init(
        positionEntityID: UUID,
        unit: ProgressUnit,
        index: Int,
        total: Int,
        location: String? = nil,
        chapterKey: String? = nil,
        chapterLocation: String? = nil,
        chapterFraction: Double? = nil,
        pageIndex: Int? = nil,
        mode: ReaderMode? = nil
    ) {
        self.positionEntityID = positionEntityID
        self.unit = unit
        self.index = index
        self.total = total
        self.location = location
        self.chapterKey = chapterKey
        self.chapterLocation = chapterLocation
        self.chapterFraction = chapterFraction
        self.pageIndex = pageIndex
        self.mode = mode
    }

    // MARK: - Actions - Opening

    /// Where the native reader opens this target inside the Book `workID`: its native locator when
    /// one was recorded, else its chapter at the chapter fraction, or its page for paged Books.
    /// Returns nil when the target carries nothing the native reader can open directly, such as a
    /// single-file PDF position, which the reader resumes from its own checkpoint.
    func destination(inWork workID: UUID) -> BookReadingDestination? {
        if positionEntityID != workID {
            return .chapterPage(chapterID: positionEntityID, pageIndex: max(0, pageIndex ?? index))
        }
        if let location, EPUBProgressLocation(serialized: location) != nil {
            return .epubLocator(location)
        }
        guard let chapterLocation, !chapterLocation.isEmpty else { return nil }
        return .epubChapter(
            BookReaderLocationTarget(location: chapterLocation, progression: chapterFraction ?? 0)
        )
    }
}

extension BookReadingTarget: Decodable {
    private enum CodingKeys: String, CodingKey {
        case positionEntityID = "positionEntityId"
        case unit, index, total, location, chapterKey, chapterLocation, chapterFraction, pageIndex, mode
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        positionEntityID = try container.decode(UUID.self, forKey: .positionEntityID)
        unit = try container.decode(ProgressUnit.self, forKey: .unit)
        index = try container.decodeFlexibleInt(forKey: .index)
        total = try container.decodeFlexibleInt(forKey: .total)
        location = try container.decodeIfPresent(String.self, forKey: .location)
        chapterKey = try container.decodeIfPresent(String.self, forKey: .chapterKey)
        chapterLocation = try container.decodeIfPresent(String.self, forKey: .chapterLocation)
        chapterFraction = try container.decodeFlexibleDoubleIfPresent(forKey: .chapterFraction)
        pageIndex = try container.decodeFlexibleIntIfPresent(forKey: .pageIndex)
        mode = try container.decodeIfPresent(ReaderMode.self, forKey: .mode)
    }
}
