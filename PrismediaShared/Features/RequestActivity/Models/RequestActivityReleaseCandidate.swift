import Foundation

public struct RequestActivityReleaseCandidate: Decodable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let indexerName: String
    public let title: String
    public let sizeBytes: Int64
    public let seeders: Int?
    public let peers: Int?
    public let `protocol`: RequestActivityDownloadProtocol
    public let accepted: Bool
    public let score: Double
    public let rejections: [RequestActivityReleaseRejection]
    public let infoURL: String?
    public let publishedAt: Date?

    private enum CodingKeys: String, CodingKey {
        case id
        case indexerName
        case title
        case sizeBytes
        case seeders
        case peers
        case `protocol`
        case accepted
        case score
        case rejections
        case infoURL = "infoUrl"
        case publishedAt
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        indexerName = try container.decode(String.self, forKey: .indexerName)
        title = try container.decode(String.self, forKey: .title)
        sizeBytes = try RequestActivityDecoding.integer64(from: container, forKey: .sizeBytes)
        seeders = try RequestActivityDecoding.optionalInteger(from: container, forKey: .seeders)
        peers = try RequestActivityDecoding.optionalInteger(from: container, forKey: .peers)
        `protocol` = try container.decode(RequestActivityDownloadProtocol.self, forKey: .protocol)
        accepted = try container.decode(Bool.self, forKey: .accepted)
        score = try RequestActivityDecoding.double(from: container, forKey: .score)
        rejections = try container.decodeIfPresent([RequestActivityReleaseRejection].self, forKey: .rejections) ?? []
        infoURL = try container.decodeIfPresent(String.self, forKey: .infoURL)
        publishedAt = try container.decodeIfPresent(Date.self, forKey: .publishedAt)
    }
}
