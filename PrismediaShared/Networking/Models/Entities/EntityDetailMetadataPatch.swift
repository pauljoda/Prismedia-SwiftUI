import Foundation

public struct EntityDetailMetadataPatch: Encodable, Hashable, Sendable {
    public let title: String?
    public let description: String?
    public let externalIDs: [String: String]
    public let urls: [String]
    public let tags: [String]
    public let studio: String?
    public let credits: [EntityDetailCreditPatch]
    public let dates: [String: String]
    public let stats: [String: Int]
    public let positions: [String: Int]
    public let classification: String?
    public let rating: Int?
    public let flags: EntityDetailMetadataFlagsPatch?

    private enum CodingKeys: String, CodingKey {
        case title
        case description
        case externalIDs = "externalIds"
        case urls
        case tags
        case studio
        case credits
        case dates
        case stats
        case positions
        case classification
        case rating
        case flags
    }

    public init(
        title: String? = nil,
        description: String? = nil,
        externalIDs: [String: String] = [:],
        urls: [String] = [],
        tags: [String] = [],
        studio: String? = nil,
        credits: [EntityDetailCreditPatch] = [],
        dates: [String: String] = [:],
        stats: [String: Int] = [:],
        positions: [String: Int] = [:],
        classification: String? = nil,
        rating: Int? = nil,
        flags: EntityDetailMetadataFlagsPatch? = nil
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
