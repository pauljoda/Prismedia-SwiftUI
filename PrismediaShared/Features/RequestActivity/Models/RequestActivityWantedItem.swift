import Foundation

public struct RequestActivityWantedItem: Decodable, Equatable, Identifiable, Sendable {
    public var id: UUID { monitorID }
    public let monitorID: UUID
    public let acquisitionID: UUID?
    public let entityID: UUID?
    public let kind: EntityKind
    public let title: String
    public let monitorStatus: EntityMonitorStatus
    public let acquisitionStatus: AcquisitionStatus?
    public let lastSearchedAt: Date?
    public let nextSearchAt: Date?
    public let ownedQuality: String?
    public let cutoffQuality: String?
    public let barrenSearches: Int
    public let posterURL: String?
    public let author: String?
    public let bookRendition: RequestActivityBookRendition?

    private enum CodingKeys: String, CodingKey {
        case monitorID = "monitorId"
        case acquisitionID = "acquisitionId"
        case entityID = "entityId"
        case kind
        case title
        case monitorStatus
        case acquisitionStatus
        case lastSearchedAt
        case nextSearchAt
        case ownedQuality
        case cutoffQuality
        case barrenSearches
        case posterURL = "posterUrl"
        case author
        case bookRendition
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        monitorID = try container.decode(UUID.self, forKey: .monitorID)
        acquisitionID = try container.decodeIfPresent(UUID.self, forKey: .acquisitionID)
        entityID = try container.decodeIfPresent(UUID.self, forKey: .entityID)
        kind = try container.decode(EntityKind.self, forKey: .kind)
        title = try container.decode(String.self, forKey: .title)
        monitorStatus = try container.decode(EntityMonitorStatus.self, forKey: .monitorStatus)
        acquisitionStatus = try container.decodeIfPresent(AcquisitionStatus.self, forKey: .acquisitionStatus)
        lastSearchedAt = try container.decodeIfPresent(Date.self, forKey: .lastSearchedAt)
        nextSearchAt = try container.decodeIfPresent(Date.self, forKey: .nextSearchAt)
        ownedQuality = try container.decodeIfPresent(String.self, forKey: .ownedQuality)
        cutoffQuality = try container.decodeIfPresent(String.self, forKey: .cutoffQuality)
        barrenSearches = try RequestActivityDecoding.integer(from: container, forKey: .barrenSearches)
        posterURL = try container.decodeIfPresent(String.self, forKey: .posterURL)
        author = try container.decodeIfPresent(String.self, forKey: .author)
        bookRendition = try container.decodeIfPresent(RequestActivityBookRendition.self, forKey: .bookRendition)
    }
}
