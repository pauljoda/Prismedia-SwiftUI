import Foundation

public struct RequestActivityHistoryEntry: Decodable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let acquisitionID: UUID?
    public let entityID: UUID?
    public let kind: EntityKind
    public let event: RequestActivityHistoryEvent
    public let title: String
    public let releaseTitle: String?
    public let indexerName: String?
    public let downloadClientName: String?
    public let qualityCode: String?
    public let formatScore: Int?
    public let message: String?
    public let createdAt: Date

    init(
        id: UUID,
        acquisitionID: UUID?,
        entityID: UUID?,
        kind: EntityKind,
        event: RequestActivityHistoryEvent,
        title: String,
        releaseTitle: String? = nil,
        indexerName: String? = nil,
        downloadClientName: String? = nil,
        qualityCode: String? = nil,
        formatScore: Int? = nil,
        message: String? = nil,
        createdAt: Date
    ) {
        self.id = id
        self.acquisitionID = acquisitionID
        self.entityID = entityID
        self.kind = kind
        self.event = event
        self.title = title
        self.releaseTitle = releaseTitle
        self.indexerName = indexerName
        self.downloadClientName = downloadClientName
        self.qualityCode = qualityCode
        self.formatScore = formatScore
        self.message = message
        self.createdAt = createdAt
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case acquisitionID = "acquisitionId"
        case entityID = "entityId"
        case kind
        case event
        case title
        case releaseTitle
        case indexerName
        case downloadClientName
        case qualityCode
        case formatScore
        case message
        case createdAt
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        acquisitionID = try container.decodeIfPresent(UUID.self, forKey: .acquisitionID)
        entityID = try container.decodeIfPresent(UUID.self, forKey: .entityID)
        kind = try container.decode(EntityKind.self, forKey: .kind)
        event = try container.decode(RequestActivityHistoryEvent.self, forKey: .event)
        title = try container.decode(String.self, forKey: .title)
        releaseTitle = try container.decodeIfPresent(String.self, forKey: .releaseTitle)
        indexerName = try container.decodeIfPresent(String.self, forKey: .indexerName)
        downloadClientName = try container.decodeIfPresent(String.self, forKey: .downloadClientName)
        qualityCode = try container.decodeIfPresent(String.self, forKey: .qualityCode)
        formatScore = try PrismediaDecoding.optionalInteger(from: container, forKey: .formatScore)
        message = try container.decodeIfPresent(String.self, forKey: .message)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
}
