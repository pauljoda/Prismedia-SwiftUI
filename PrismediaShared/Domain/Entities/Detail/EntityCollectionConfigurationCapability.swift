import Foundation

/// Collection membership configuration and caller permissions.
public struct EntityCollectionConfigurationCapability: Decodable, Hashable, Sendable {
    public let isShared: Bool
    public let canEdit: Bool
    public let mode: String
    public let ruleTreeJSON: String?
    public let coverMode: String
    public let lastRefreshedAt: String?

    private enum CodingKeys: String, CodingKey {
        case isShared
        case canEdit
        case mode
        case ruleTreeJSON = "ruleTreeJson"
        case coverMode
        case lastRefreshedAt
    }
}
