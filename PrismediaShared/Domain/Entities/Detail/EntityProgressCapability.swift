import Foundation

/// A work's non-time progress: the single last-used main cursor, completion and coverage, plus,
/// for kinds that declare consumption modalities (Books on 3.8+ servers), each modality's exact
/// checkpoint.
public struct EntityProgressCapability: Hashable, Sendable {
    // MARK: - Variables

    /// Exact per-modality positions, one per recorded modality.
    public let checkpoints: [EntityProgressCheckpoint]
    public let currentEntityID: UUID?
    public let unit: ProgressUnit
    public let index: Int
    public let total: Int
    public let mode: ReaderMode?
    public let completedAt: Date?
    public let updatedAt: Date?
    public let workIndex: Int?
    public let workTotal: Int?
    public let location: String?
    public let consumedCount: Int
    public let consumedTotal: Int?
    public let consumedPercent: Double
    /// Modality of the newest checkpoint.
    public let lastModality: ConsumptionModality?

    /// The exact reading checkpoint presented as a cursor while keeping the work's completion and
    /// coverage. Servers that keep modality checkpoints may place the main cursor from listening,
    /// so reading surfaces resume and echo this position instead. Without a reading checkpoint
    /// (older servers and kinds without modalities) the main cursor is the reading position.
    public var readingPosition: Self {
        guard let reading = checkpoint(for: .reading) else { return self }
        return Self(
            currentEntityID: reading.positionEntityID,
            unit: reading.unit,
            index: reading.index,
            total: reading.total,
            mode: reading.mode,
            completedAt: completedAt,
            updatedAt: reading.updatedAt,
            workIndex: reading.workIndex,
            workTotal: reading.workTotal,
            location: reading.location,
            consumedCount: consumedCount,
            consumedTotal: consumedTotal,
            consumedPercent: consumedPercent,
            lastModality: lastModality,
            checkpoints: checkpoints
        )
    }

    // MARK: - Initializers

    public init(
        currentEntityID: UUID?,
        unit: ProgressUnit,
        index: Int,
        total: Int,
        mode: ReaderMode?,
        completedAt: Date?,
        updatedAt: Date?,
        workIndex: Int?,
        workTotal: Int?,
        location: String?,
        consumedCount: Int = 0,
        consumedTotal: Int? = nil,
        consumedPercent: Double = 0,
        lastModality: ConsumptionModality? = nil,
        checkpoints: [EntityProgressCheckpoint] = []
    ) {
        self.currentEntityID = currentEntityID
        self.unit = unit
        self.index = index
        self.total = total
        self.mode = mode
        self.completedAt = completedAt
        self.updatedAt = updatedAt
        self.workIndex = workIndex
        self.workTotal = workTotal
        self.location = location
        self.consumedCount = consumedCount
        self.consumedTotal = consumedTotal
        self.consumedPercent = consumedPercent
        self.lastModality = lastModality
        self.checkpoints = checkpoints
    }

    // MARK: - Actions - Checkpoints

    /// The exact checkpoint recorded for `modality`, when the server keeps one.
    public func checkpoint(for modality: ConsumptionModality) -> EntityProgressCheckpoint? {
        checkpoints.first { $0.modality == modality }
    }
}

extension EntityProgressCapability: Decodable {
    private enum CodingKeys: String, CodingKey {
        case currentEntityID = "currentEntityId"
        case unit, index, total, mode, completedAt, updatedAt, workIndex, workTotal, location
        case consumedCount, consumedTotal, consumedPercent, lastModality, checkpoints
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        currentEntityID = try container.decodeIfPresent(UUID.self, forKey: .currentEntityID)
        unit = try container.decode(ProgressUnit.self, forKey: .unit)
        index = try container.decodeFlexibleInt(forKey: .index)
        total = try container.decodeFlexibleInt(forKey: .total)
        mode = try container.decodeIfPresent(ReaderMode.self, forKey: .mode)
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        workIndex = try container.decodeFlexibleIntIfPresent(forKey: .workIndex)
        workTotal = try container.decodeFlexibleIntIfPresent(forKey: .workTotal)
        location = try container.decodeIfPresent(String.self, forKey: .location)
        consumedCount = try container.decodeFlexibleIntIfPresent(forKey: .consumedCount) ?? 0
        consumedTotal = try container.decodeFlexibleIntIfPresent(forKey: .consumedTotal)
        consumedPercent = try container.decodeFlexibleDoubleIfPresent(forKey: .consumedPercent) ?? 0
        lastModality = try container.decodeIfPresent(ConsumptionModality.self, forKey: .lastModality)
        checkpoints = try container.decodeIfPresent([EntityProgressCheckpoint].self, forKey: .checkpoints) ?? []
    }
}
