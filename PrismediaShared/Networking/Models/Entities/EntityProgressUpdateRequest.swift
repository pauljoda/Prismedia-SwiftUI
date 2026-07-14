import Foundation

public struct EntityProgressUpdateRequest: Encodable, Hashable, Sendable {
    public let currentEntityID: UUID
    public let unit: ProgressUnit
    public let index: Int
    public let total: Int
    public let mode: ReaderMode?
    public let completed: Bool?
    public let reset: Bool
    public let location: String?

    private enum CodingKeys: String, CodingKey {
        case currentEntityID = "currentEntityId"
        case unit, index, total, mode, completed, reset, location
    }

    public init(
        currentEntityID: UUID,
        unit: ProgressUnit,
        index: Int,
        total: Int,
        mode: ReaderMode?,
        completed: Bool?,
        reset: Bool = false,
        location: String? = nil
    ) {
        self.currentEntityID = currentEntityID
        self.unit = unit
        self.index = index
        self.total = total
        self.mode = mode
        self.completed = completed
        self.reset = reset
        self.location = location
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(currentEntityID, forKey: .currentEntityID)
        try container.encode(unit, forKey: .unit)
        try container.encode(index, forKey: .index)
        try container.encode(total, forKey: .total)
        try container.encodeIfPresent(mode, forKey: .mode)
        if mode == nil { try container.encodeNil(forKey: .mode) }
        try container.encodeIfPresent(completed, forKey: .completed)
        if completed == nil { try container.encodeNil(forKey: .completed) }
        try container.encode(reset, forKey: .reset)
        try container.encodeIfPresent(location, forKey: .location)
        if location == nil { try container.encodeNil(forKey: .location) }
    }
}
