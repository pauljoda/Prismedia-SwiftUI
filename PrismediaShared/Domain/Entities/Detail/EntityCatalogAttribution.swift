import Foundation

/// Source credit and licensing statements accepted with one imported acquisition.
public struct EntityCatalogAttribution: Decodable, Hashable, Sendable {
    public let sourceURL: String
    public let creator: String?
    public let credit: String?
    public let licenseName: String?
    public let licenseURL: String?
    public let usageTerms: String?
    public let attributionRequired: Bool?

    private enum CodingKeys: String, CodingKey {
        case sourceURL = "sourceUrl"
        case creator
        case credit
        case licenseName
        case licenseURL = "licenseUrl"
        case usageTerms
        case attributionRequired
    }
}
