import Foundation

/// Collection-specific fields returned after create and full-update commands.
public struct CollectionDefinition: Identifiable, Decodable, Hashable, Sendable {
    public let id: UUID
    public let kind: EntityKind
    public let title: String
    public let capabilities: [EntityCapability]
    public let mode: CollectionMode?
    public let ruleTreeJSON: String?
    public let coverMode: CollectionCoverMode?
    public let coverItemID: UUID?
    public let lastRefreshedAt: Date?

    private enum CodingKeys: String, CodingKey {
        case id
        case kind
        case title
        case capabilities
        case mode
        case ruleTreeJSON = "ruleTreeJson"
        case coverMode
        case coverItemID = "coverItemId"
        case lastRefreshedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        kind = try container.decode(EntityKind.self, forKey: .kind)
        title = try container.decode(String.self, forKey: .title)
        capabilities = try container.decodeIfPresent([EntityCapability].self, forKey: .capabilities) ?? []
        mode = try container.decodeIfPresent(CollectionMode.self, forKey: .mode)
        ruleTreeJSON = try container.decodeIfPresent(String.self, forKey: .ruleTreeJSON)
        coverMode = try container.decodeIfPresent(CollectionCoverMode.self, forKey: .coverMode)
        coverItemID = try container.decodeIfPresent(UUID.self, forKey: .coverItemID)
        lastRefreshedAt = try container.decodeIfPresent(Date.self, forKey: .lastRefreshedAt)
    }
}
