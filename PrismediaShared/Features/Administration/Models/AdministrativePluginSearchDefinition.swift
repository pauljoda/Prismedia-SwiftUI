import Foundation

public struct AdministrativePluginSearchDefinition: Decodable, Hashable, Sendable {
    public let fields: [AdministrativePluginSearchField]
}
