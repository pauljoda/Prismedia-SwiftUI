import Foundation

/// Where the current user can resume a Book, owned by the server. Exact targets are the recorded
/// positions; switch targets align the other modality's position. Continue targets are where each
/// format continues: reading and listening of a Linked Book move one shared position, so a format
/// continues from the other one's newer position whenever it maps chapter to chapter.
public struct BookResumeProjection: Equatable, Hashable, Sendable {
    // MARK: - Variables

    /// Modality of the newest checkpoint.
    public let lastModality: ConsumptionModality?
    public let completedAt: Date?
    /// Exact target of the newest resumable checkpoint; nil when finished or never started.
    public let continueTarget: BookAlignedTarget?
    /// Recorded reading position, while it is still worth resuming.
    public let exactReading: BookReadingTarget?
    /// Recorded listening position, while it is still worth resuming.
    public let exactListening: BookListeningTarget?
    /// Reading destination aligned from the listening position, or its gap.
    public let switchToReading: BookAlignedTarget
    /// Listening destination aligned from the reading position, or its gap.
    public let switchToListening: BookAlignedTarget
    /// Both sides anchored on the newest resumable position, or a fresh start.
    public let combined: BookAlignedTarget
    /// Where continuing to read opens, or nil from a server that predates continue targets.
    public let continueReading: BookAlignedTarget?
    /// Where continuing to listen opens, or nil from a server that predates continue targets.
    public let continueListening: BookAlignedTarget?

    /// Alignment row holding the position reading continues from.
    var readingRowID: String? {
        if let continueReading { return continueReading.aligned?.reading == nil ? nil : continueReading.rowID }
        return exactReading == nil ? nil : switchToListening.rowID
    }

    /// Alignment row holding the position listening continues from.
    var listeningRowID: String? {
        if let continueListening { return continueListening.aligned?.listening == nil ? nil : continueListening.rowID }
        return exactListening == nil ? nil : switchToReading.rowID
    }

    // MARK: - Initializers

    public init(
        lastModality: ConsumptionModality? = nil,
        completedAt: Date? = nil,
        continueTarget: BookAlignedTarget? = nil,
        exactReading: BookReadingTarget? = nil,
        exactListening: BookListeningTarget? = nil,
        switchToReading: BookAlignedTarget,
        switchToListening: BookAlignedTarget,
        combined: BookAlignedTarget,
        continueReading: BookAlignedTarget? = nil,
        continueListening: BookAlignedTarget? = nil
    ) {
        self.lastModality = lastModality
        self.completedAt = completedAt
        self.continueTarget = continueTarget
        self.exactReading = exactReading
        self.exactListening = exactListening
        self.switchToReading = switchToReading
        self.switchToListening = switchToListening
        self.combined = combined
        self.continueReading = continueReading
        self.continueListening = continueListening
    }

    // MARK: - Actions - Continue

    /// Where "Continue Reading" opens, or nil when reading has nothing to continue from. A server
    /// without continue targets resumes the exact reading position, else, for a Linked Book, the
    /// position aligned from listening.
    func readingResume(isLinked: Bool) -> BookAlignedTarget? {
        if let continueReading { return continueReading.aligned?.reading == nil ? nil : continueReading }
        if let exactReading { return BookAlignedTarget(rowID: switchToListening.rowID, reading: exactReading) }
        guard isLinked, let aligned = switchToReading.aligned, aligned.reading != nil else { return nil }
        return aligned
    }

    /// Where "Continue Listening" starts, or nil when listening has nothing to continue from. A server
    /// without continue targets resumes the exact listening position, else, for a Linked Book, the
    /// position aligned from reading.
    func listeningResume(isLinked: Bool) -> BookAlignedTarget? {
        if let continueListening { return continueListening.aligned?.listening == nil ? nil : continueListening }
        if let exactListening { return BookAlignedTarget(rowID: switchToReading.rowID, listening: exactListening) }
        guard isLinked, let aligned = switchToListening.aligned, aligned.listening != nil else { return nil }
        return aligned
    }
}

extension BookResumeProjection: Decodable {
    private enum CodingKeys: String, CodingKey {
        case lastModality, completedAt
        case continueTarget = "continue"
        case exactReading, exactListening, switchToReading, switchToListening, combined
        case continueReading, continueListening
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        lastModality = try container.decodeIfPresent(ConsumptionModality.self, forKey: .lastModality)
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        continueTarget = try container.decodeIfPresent(BookAlignedTarget.self, forKey: .continueTarget)
        exactReading = try container.decodeIfPresent(BookReadingTarget.self, forKey: .exactReading)
        exactListening = try container.decodeIfPresent(BookListeningTarget.self, forKey: .exactListening)
        switchToReading = try container.decode(BookAlignedTarget.self, forKey: .switchToReading)
        switchToListening = try container.decode(BookAlignedTarget.self, forKey: .switchToListening)
        combined = try container.decode(BookAlignedTarget.self, forKey: .combined)
        continueReading = try container.decodeIfPresent(BookAlignedTarget.self, forKey: .continueReading)
        continueListening = try container.decodeIfPresent(BookAlignedTarget.self, forKey: .continueListening)
    }
}
