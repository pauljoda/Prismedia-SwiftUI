import Foundation

/// One modality's exact recorded position on a work that keeps independent reading and listening
/// checkpoints, as reported by the server's progress capability (3.8+).
public struct EntityProgressCheckpoint: Equatable, Hashable, Sendable {
    // MARK: - Variables

    public let modality: ConsumptionModality
    /// The Book or chapter Entity for reading, or the audio track for listening.
    public let positionEntityID: UUID
    public let unit: ProgressUnit
    public let index: Int
    public let total: Int
    /// Exact offset on the audio track, for listening checkpoints.
    public let offsetSeconds: Double?
    public let markerID: UUID?
    public let mode: ReaderMode?
    /// Opaque reader locator, for reading checkpoints.
    public let location: String?
    public let updatedAt: Date
    public let workIndex: Int?
    public let workTotal: Int?

    // MARK: - Initializers

    public init(
        modality: ConsumptionModality,
        positionEntityID: UUID,
        unit: ProgressUnit,
        index: Int,
        total: Int,
        offsetSeconds: Double? = nil,
        markerID: UUID? = nil,
        mode: ReaderMode? = nil,
        location: String? = nil,
        updatedAt: Date,
        workIndex: Int? = nil,
        workTotal: Int? = nil
    ) {
        self.modality = modality
        self.positionEntityID = positionEntityID
        self.unit = unit
        self.index = index
        self.total = total
        self.offsetSeconds = offsetSeconds
        self.markerID = markerID
        self.mode = mode
        self.location = location
        self.updatedAt = updatedAt
        self.workIndex = workIndex
        self.workTotal = workTotal
    }
}

extension EntityProgressCheckpoint: Decodable {
    private enum CodingKeys: String, CodingKey {
        case modality
        case positionEntityID = "positionEntityId"
        case unit, index, total, offsetSeconds
        case markerID = "markerId"
        case mode, location, updatedAt, workIndex, workTotal
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        modality = try container.decode(ConsumptionModality.self, forKey: .modality)
        positionEntityID = try container.decode(UUID.self, forKey: .positionEntityID)
        unit = try container.decode(ProgressUnit.self, forKey: .unit)
        index = try container.decodeFlexibleInt(forKey: .index)
        total = try container.decodeFlexibleInt(forKey: .total)
        offsetSeconds = try container.decodeFlexibleDoubleIfPresent(forKey: .offsetSeconds)
        markerID = try container.decodeIfPresent(UUID.self, forKey: .markerID)
        mode = try container.decodeIfPresent(ReaderMode.self, forKey: .mode)
        location = try container.decodeIfPresent(String.self, forKey: .location)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        workIndex = try container.decodeFlexibleIntIfPresent(forKey: .workIndex)
        workTotal = try container.decodeFlexibleIntIfPresent(forKey: .workTotal)
    }
}
