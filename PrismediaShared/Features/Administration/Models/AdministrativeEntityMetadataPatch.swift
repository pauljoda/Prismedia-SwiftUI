import Foundation

public struct AdministrativeEntityMetadataPatch: Codable, Hashable, Sendable {
    public let title: String?
    public let description: String?
    public let externalIDs: [String: String]
    public let urls: [String]
    public let tags: [String]
    public let studio: String?
    public let credits: [AdministrativeCreditPatch]
    public let dates: [String: String]
    public let stats: [String: Int]
    public let positions: [String: Int]
    public let classification: String?
    public let rating: Int?
    public let flags: AdministrativeEntityMetadataFlagsPatch?

    enum CodingKeys: String, CodingKey {
        case title, description
        case externalIDs = "externalIds"
        case urls, tags, studio, credits, dates, stats, positions, classification, rating, flags
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        // Sparse patches serialize empty collections as explicit nulls.
        externalIDs = try container.decodeIfPresent([String: String].self, forKey: .externalIDs) ?? [:]
        urls = try container.decodeIfPresent([String].self, forKey: .urls) ?? []
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        studio = try container.decodeIfPresent(String.self, forKey: .studio)
        credits = try container.decodeIfPresent([AdministrativeCreditPatch].self, forKey: .credits) ?? []
        dates = try container.decodeIfPresent([String: String].self, forKey: .dates) ?? [:]
        stats = try container.decodeIfPresent([String: Int].self, forKey: .stats) ?? [:]
        positions = try container.decodeIfPresent([String: Int].self, forKey: .positions) ?? [:]
        classification = try container.decodeIfPresent(String.self, forKey: .classification)
        rating = try container.decodeIfPresent(Int.self, forKey: .rating)
        flags = try container.decodeIfPresent(AdministrativeEntityMetadataFlagsPatch.self, forKey: .flags)
    }

    public init(
        title: String? = nil,
        description: String? = nil,
        externalIDs: [String: String] = [:],
        urls: [String] = [],
        tags: [String] = [],
        studio: String? = nil,
        credits: [AdministrativeCreditPatch] = [],
        dates: [String: String] = [:],
        stats: [String: Int] = [:],
        positions: [String: Int] = [:],
        classification: String? = nil,
        rating: Int? = nil,
        flags: AdministrativeEntityMetadataFlagsPatch? = nil
    ) {
        self.title = title
        self.description = description
        self.externalIDs = externalIDs
        self.urls = urls
        self.tags = tags
        self.studio = studio
        self.credits = credits
        self.dates = dates
        self.stats = stats
        self.positions = positions
        self.classification = classification
        self.rating = rating
        self.flags = flags
    }
}
