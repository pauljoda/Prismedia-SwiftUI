import Foundation

public struct AdministrativeIdentifyQuery: Codable, Hashable, Sendable {
    public let title: String?
    public let url: String?
    public let externalIDs: [String: String]?
    public let requireChoice: Bool?
    public let fields: [String: String]?
    public let limit: Int

    public init(
        title: String? = nil,
        url: String? = nil,
        externalIDs: [String: String]? = nil,
        requireChoice: Bool? = nil,
        fields: [String: String]? = nil,
        limit: Int = 25
    ) {
        self.title = title
        self.url = url
        self.externalIDs = externalIDs
        self.requireChoice = requireChoice
        self.fields = fields
        self.limit = limit
    }

    enum CodingKeys: String, CodingKey {
        case title, url
        case externalIDs = "externalIds"
        case requireChoice, fields, limit
    }
}
