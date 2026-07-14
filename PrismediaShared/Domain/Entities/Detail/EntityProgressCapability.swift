import Foundation

public struct EntityProgressCapability: Decodable, Hashable, Sendable {
    public let currentEntityID: UUID?
    public let unit: ProgressUnit
    public let index: Int
    public let total: Int
    public let mode: ReaderMode?
    public let completedAt: String?
    public let updatedAt: String?
    public let workIndex: Int?
    public let workTotal: Int?
    public let location: String?

    private enum CodingKeys: String, CodingKey {
        case currentEntityID = "currentEntityId"
        case unit
        case index
        case total
        case mode
        case completedAt
        case updatedAt
        case workIndex
        case workTotal
        case location
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        currentEntityID = try container.decodeIfPresent(UUID.self, forKey: .currentEntityID)
        unit = try container.decode(ProgressUnit.self, forKey: .unit)
        index = try container.decodeFlexibleInt(forKey: .index)
        total = try container.decodeFlexibleInt(forKey: .total)
        mode = try container.decodeIfPresent(ReaderMode.self, forKey: .mode)
        completedAt = try container.decodeIfPresent(String.self, forKey: .completedAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        workIndex = try container.decodeFlexibleIntIfPresent(forKey: .workIndex)
        workTotal = try container.decodeFlexibleIntIfPresent(forKey: .workTotal)
        location = try container.decodeIfPresent(String.self, forKey: .location)
    }

    public init(
        currentEntityID: UUID?,
        unit: ProgressUnit,
        index: Int,
        total: Int,
        mode: ReaderMode?,
        completedAt: String?,
        updatedAt: String?,
        workIndex: Int?,
        workTotal: Int?,
        location: String?
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
    }
}
