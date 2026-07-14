import Foundation

public struct AdministrativePluginSupport: Decodable, Hashable, Sendable {
    public let entityKind: String
    public let actions: [String]
    public let identityNamespaces: [String]?
    public let search: AdministrativePluginSearchDefinition?
    public let identityUrls: [AdministrativePluginIdentityURLFormat]?

    public init(
        entityKind: String,
        actions: [String],
        identityNamespaces: [String]? = nil,
        search: AdministrativePluginSearchDefinition? = nil,
        identityUrls: [AdministrativePluginIdentityURLFormat]? = nil
    ) {
        self.entityKind = entityKind
        self.actions = actions
        self.identityNamespaces = identityNamespaces
        self.search = search
        self.identityUrls = identityUrls
    }
}
