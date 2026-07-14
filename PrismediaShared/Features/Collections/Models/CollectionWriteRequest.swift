import Foundation

public struct CollectionWriteRequest: Encodable, Hashable, Sendable {
    public let title: String
    public let description: String?
    public let mode: CollectionMode?
    public let ruleTreeJSON: String?
    public let coverMode: CollectionCoverMode?
    public let coverItemID: UUID?
    public let isNsfw: Bool?

    public init(
        title: String,
        description: String? = nil,
        mode: CollectionMode? = nil,
        ruleTreeJSON: String? = nil,
        coverMode: CollectionCoverMode? = nil,
        coverItemID: UUID? = nil,
        isNsfw: Bool? = nil
    ) {
        self.title = title
        self.description = description
        self.mode = mode
        self.ruleTreeJSON = ruleTreeJSON
        self.coverMode = coverMode
        self.coverItemID = coverItemID
        self.isNsfw = isNsfw
    }

    private enum CodingKeys: String, CodingKey {
        case title
        case description
        case mode
        case ruleTreeJSON = "ruleTreeJson"
        case coverMode
        case coverItemID = "coverItemId"
        case isNsfw
    }
}
