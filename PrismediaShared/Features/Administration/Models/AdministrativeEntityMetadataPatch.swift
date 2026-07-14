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
}
