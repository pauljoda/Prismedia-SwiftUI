import Foundation

/// Chapter-scoped conversion from an audiobook part into the Book's canonical cursor.
public struct BookProgressTrackMapping: Codable, Equatable, Sendable {
    public let trackID: UUID
    public let currentEntityID: UUID
    public let unit: ProgressUnit
    public let startIndex: Int
    public let endIndex: Int
    public let total: Int
    public let mode: ReaderMode?

    private enum CodingKeys: String, CodingKey {
        case trackID = "trackId"
        case currentEntityID = "currentEntityId"
        case unit, startIndex, endIndex, total, mode
    }

    public init(
        trackID: UUID,
        currentEntityID: UUID,
        unit: ProgressUnit,
        startIndex: Int,
        endIndex: Int,
        total: Int,
        mode: ReaderMode?
    ) {
        self.trackID = trackID
        self.currentEntityID = currentEntityID
        self.unit = unit
        self.startIndex = startIndex
        self.endIndex = endIndex
        self.total = total
        self.mode = mode
    }
}
