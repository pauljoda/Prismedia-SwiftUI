import Foundation

public struct EntityMonitor: Decodable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let kind: EntityKind
    public let acquisitionID: UUID?
    public let status: EntityMonitorStatus
    public let title: String
    public let author: String?
    public let acquisitionStatus: AcquisitionStatus?
    public let createdAt: Date
    public let updatedAt: Date
    public let entityID: UUID?
    public let preset: String
    public let bookRendition: RequestActivityBookRendition?

    private enum CodingKeys: String, CodingKey {
        case id
        case kind
        case acquisitionID = "acquisitionId"
        case status
        case title
        case author
        case acquisitionStatus
        case createdAt
        case updatedAt
        case entityID = "entityId"
        case preset
        case bookRendition
    }

    public init(
        id: UUID,
        kind: EntityKind,
        acquisitionID: UUID?,
        status: EntityMonitorStatus,
        title: String,
        author: String?,
        acquisitionStatus: AcquisitionStatus?,
        createdAt: Date,
        updatedAt: Date,
        entityID: UUID?,
        preset: String = "all",
        bookRendition: RequestActivityBookRendition? = nil
    ) {
        self.id = id
        self.kind = kind
        self.acquisitionID = acquisitionID
        self.status = status
        self.title = title
        self.author = author
        self.acquisitionStatus = acquisitionStatus
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.entityID = entityID
        self.preset = preset
        self.bookRendition = bookRendition
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        kind = try container.decode(EntityKind.self, forKey: .kind)
        acquisitionID = try container.decodeIfPresent(UUID.self, forKey: .acquisitionID)
        status = try container.decode(EntityMonitorStatus.self, forKey: .status)
        title = try container.decode(String.self, forKey: .title)
        author = try container.decodeIfPresent(String.self, forKey: .author)
        acquisitionStatus = try container.decodeIfPresent(AcquisitionStatus.self, forKey: .acquisitionStatus)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        entityID = try container.decodeIfPresent(UUID.self, forKey: .entityID)
        preset = try container.decodeIfPresent(String.self, forKey: .preset) ?? "all"
        bookRendition = try container.decodeIfPresent(RequestActivityBookRendition.self, forKey: .bookRendition)
    }
}
