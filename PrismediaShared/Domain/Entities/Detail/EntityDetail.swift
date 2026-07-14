import Foundation

/// Full shared entity document returned by `GET /api/entities/{id}`.
public struct EntityDetail: Identifiable, Decodable, Hashable, Sendable {
    public let id: UUID
    public let kind: EntityKind
    public let title: String
    public let parentEntityID: UUID?
    public let sortOrder: Int?
    public let bookType: String?
    public let bookFormat: BookFormat?
    public let coverPageID: UUID?
    public let hasSourceMedia: Bool
    public let capabilities: [EntityCapability]
    public let childrenByKind: [EntityGroup]
    public let relationships: [EntityGroup]

    private enum CodingKeys: String, CodingKey {
        case id
        case kind
        case title
        case parentEntityID = "parentEntityId"
        case sortOrder
        case bookType
        case bookFormat = "format"
        case coverPageID = "coverPageId"
        case hasSourceMedia
        case capabilities
        case childrenByKind
        case relationships
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        kind = try container.decode(EntityKind.self, forKey: .kind)
        title = try container.decode(String.self, forKey: .title)
        parentEntityID = try container.decodeIfPresent(UUID.self, forKey: .parentEntityID)
        sortOrder = try container.decodeFlexibleIntIfPresent(forKey: .sortOrder)
        bookType = try container.decodeIfPresent(String.self, forKey: .bookType)
        bookFormat = try container.decodeIfPresent(BookFormat.self, forKey: .bookFormat)
        coverPageID = try container.decodeIfPresent(UUID.self, forKey: .coverPageID)
        hasSourceMedia = try container.decodeIfPresent(Bool.self, forKey: .hasSourceMedia) ?? false
        capabilities = try container.decodeIfPresent([EntityCapability].self, forKey: .capabilities) ?? []
        childrenByKind = try container.decodeIfPresent([EntityGroup].self, forKey: .childrenByKind) ?? []
        relationships = try container.decodeIfPresent([EntityGroup].self, forKey: .relationships) ?? []
    }

    init(
        id: UUID,
        kind: EntityKind,
        title: String,
        parentEntityID: UUID?,
        sortOrder: Int?,
        bookType: String? = nil,
        bookFormat: BookFormat? = nil,
        coverPageID: UUID? = nil,
        hasSourceMedia: Bool,
        capabilities: [EntityCapability],
        childrenByKind: [EntityGroup],
        relationships: [EntityGroup]
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.parentEntityID = parentEntityID
        self.sortOrder = sortOrder
        self.bookType = bookType
        self.bookFormat = bookFormat
        self.coverPageID = coverPageID
        self.hasSourceMedia = hasSourceMedia
        self.capabilities = capabilities
        self.childrenByKind = childrenByKind
        self.relationships = relationships
    }

}
