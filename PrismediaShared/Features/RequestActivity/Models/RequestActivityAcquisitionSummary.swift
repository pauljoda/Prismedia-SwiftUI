import Foundation

public struct RequestActivityAcquisitionSummary: Decodable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let status: AcquisitionStatus
    public let statusMessage: String?
    public let title: String
    public let author: String?
    public let series: String?
    public let year: Int?
    public let posterURL: String?
    public let progress: Double?
    public let createdAt: Date
    public let updatedAt: Date
    public let description: String?
    public let kind: EntityKind
    public let entityID: UUID?
    public let hasResumableImport: Bool
    public let bookRendition: RequestActivityBookRendition?

    private enum CodingKeys: String, CodingKey {
        case id
        case status
        case statusMessage
        case title
        case author
        case series
        case year
        case posterURL = "posterUrl"
        case progress
        case createdAt
        case updatedAt
        case description
        case kind
        case entityID = "entityId"
        case hasResumableImport
        case bookRendition
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        status = try container.decode(AcquisitionStatus.self, forKey: .status)
        statusMessage = try container.decodeIfPresent(String.self, forKey: .statusMessage)
        title = try container.decode(String.self, forKey: .title)
        author = try container.decodeIfPresent(String.self, forKey: .author)
        series = try container.decodeIfPresent(String.self, forKey: .series)
        year = try RequestActivityDecoding.optionalInteger(from: container, forKey: .year)
        posterURL = try container.decodeIfPresent(String.self, forKey: .posterURL)
        progress = try RequestActivityDecoding.optionalDouble(from: container, forKey: .progress)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        kind = try container.decodeIfPresent(EntityKind.self, forKey: .kind) ?? .book
        entityID = try container.decodeIfPresent(UUID.self, forKey: .entityID)
        hasResumableImport = try container.decodeIfPresent(Bool.self, forKey: .hasResumableImport) ?? false
        bookRendition = try container.decodeIfPresent(RequestActivityBookRendition.self, forKey: .bookRendition)
    }
}
