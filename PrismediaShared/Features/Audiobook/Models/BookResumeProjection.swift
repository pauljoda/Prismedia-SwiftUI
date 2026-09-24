import Foundation

/// Where the current user can resume a Book, owned by the server. Exact targets are the recorded
/// positions; switch targets align the other modality's position and are offered next to, never
/// instead of, the destination's exact position.
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

    /// Alignment row holding the exact reading position.
    var readingRowID: String? {
        exactReading == nil ? nil : switchToListening.rowID
    }

    /// Alignment row holding the exact listening position.
    var listeningRowID: String? {
        exactListening == nil ? nil : switchToReading.rowID
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
        combined: BookAlignedTarget
    ) {
        self.lastModality = lastModality
        self.completedAt = completedAt
        self.continueTarget = continueTarget
        self.exactReading = exactReading
        self.exactListening = exactListening
        self.switchToReading = switchToReading
        self.switchToListening = switchToListening
        self.combined = combined
    }
}

extension BookResumeProjection: Decodable {
    private enum CodingKeys: String, CodingKey {
        case lastModality, completedAt
        case continueTarget = "continue"
        case exactReading, exactListening, switchToReading, switchToListening, combined
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
    }
}
