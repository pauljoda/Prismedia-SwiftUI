import Foundation

public struct EntityProviderIdentityCapability: Decodable, Hashable, Sendable {
    public let pluginID: String
    public let identityNamespace: String
    public let identityValue: String
    public let url: String?

    private enum CodingKeys: String, CodingKey {
        case pluginID = "pluginId"
        case identityNamespace
        case identityValue
        case url
    }
}
