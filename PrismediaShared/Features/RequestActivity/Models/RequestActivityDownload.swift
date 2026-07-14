import Foundation

public struct RequestActivityDownload: Decodable, Equatable, Identifiable, Sendable {
    public var id: UUID { acquisitionID }
    public let acquisitionID: UUID
    public let kind: EntityKind
    public let title: String
    public let status: AcquisitionStatus
    public let statusMessage: String?
    public let progress: Double?
    public let updatedAt: Date
    public let entityID: UUID?
    public let posterURL: String?
    public let transferState: String?
    public let totalSizeBytes: Int64?
    public let downloadSpeedBytesPerSecond: Double?
    public let etaSeconds: Int64?
    public let seeds: Int?
    public let peers: Int?
    public let clientName: String?
    public let author: String?
    public let series: String?
    public let year: Int?
    public let bookRendition: RequestActivityBookRendition?

    private enum CodingKeys: String, CodingKey {
        case acquisitionID = "acquisitionId"
        case kind
        case title
        case status
        case statusMessage
        case progress
        case updatedAt
        case entityID = "entityId"
        case posterURL = "posterUrl"
        case transferState
        case totalSizeBytes
        case downloadSpeedBytesPerSecond
        case etaSeconds
        case seeds
        case peers
        case clientName
        case author
        case series
        case year
        case bookRendition
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        acquisitionID = try container.decode(UUID.self, forKey: .acquisitionID)
        kind = try container.decode(EntityKind.self, forKey: .kind)
        title = try container.decode(String.self, forKey: .title)
        status = try container.decode(AcquisitionStatus.self, forKey: .status)
        statusMessage = try container.decodeIfPresent(String.self, forKey: .statusMessage)
        progress = try RequestActivityDecoding.optionalDouble(from: container, forKey: .progress)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        entityID = try container.decodeIfPresent(UUID.self, forKey: .entityID)
        posterURL = try container.decodeIfPresent(String.self, forKey: .posterURL)
        transferState = try container.decodeIfPresent(String.self, forKey: .transferState)
        totalSizeBytes = try RequestActivityDecoding.optionalInteger64(from: container, forKey: .totalSizeBytes)
        downloadSpeedBytesPerSecond = try RequestActivityDecoding.optionalDouble(
            from: container,
            forKey: .downloadSpeedBytesPerSecond
        )
        etaSeconds = try RequestActivityDecoding.optionalInteger64(from: container, forKey: .etaSeconds)
        seeds = try RequestActivityDecoding.optionalInteger(from: container, forKey: .seeds)
        peers = try RequestActivityDecoding.optionalInteger(from: container, forKey: .peers)
        clientName = try container.decodeIfPresent(String.self, forKey: .clientName)
        author = try container.decodeIfPresent(String.self, forKey: .author)
        series = try container.decodeIfPresent(String.self, forKey: .series)
        year = try RequestActivityDecoding.optionalInteger(from: container, forKey: .year)
        bookRendition = try container.decodeIfPresent(RequestActivityBookRendition.self, forKey: .bookRendition)
    }
}
