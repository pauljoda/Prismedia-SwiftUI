import Foundation

public struct EntityAcquisitionSummary: Decodable, Equatable, Identifiable, Sendable {
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

    public init(
        id: UUID,
        status: AcquisitionStatus,
        statusMessage: String? = nil,
        title: String,
        author: String? = nil,
        series: String? = nil,
        year: Int? = nil,
        posterURL: String? = nil,
        progress: Double? = nil,
        createdAt: Date,
        updatedAt: Date,
        description: String? = nil,
        kind: EntityKind = .book,
        entityID: UUID? = nil,
        hasResumableImport: Bool = false
    ) {
        self.id = id
        self.status = status
        self.statusMessage = statusMessage
        self.title = title
        self.author = author
        self.series = series
        self.year = year
        self.posterURL = posterURL
        self.progress = progress
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.description = description
        self.kind = kind
        self.entityID = entityID
        self.hasResumableImport = hasResumableImport
    }

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
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        status = try container.decode(AcquisitionStatus.self, forKey: .status)
        statusMessage = try container.decodeIfPresent(String.self, forKey: .statusMessage)
        title = try container.decode(String.self, forKey: .title)
        author = try container.decodeIfPresent(String.self, forKey: .author)
        series = try container.decodeIfPresent(String.self, forKey: .series)
        year = try container.decodeIfPresent(Int.self, forKey: .year)
        posterURL = try container.decodeIfPresent(String.self, forKey: .posterURL)
        progress = try container.decodeIfPresent(Double.self, forKey: .progress)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        kind = try container.decodeIfPresent(EntityKind.self, forKey: .kind) ?? .book
        entityID = try container.decodeIfPresent(UUID.self, forKey: .entityID)
        hasResumableImport = try container.decodeIfPresent(Bool.self, forKey: .hasResumableImport) ?? false
    }
}
