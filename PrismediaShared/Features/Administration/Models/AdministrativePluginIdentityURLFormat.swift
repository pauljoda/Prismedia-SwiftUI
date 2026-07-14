import Foundation

public struct AdministrativePluginIdentityURLFormat: Decodable, Hashable, Sendable {
    public let identityNamespace: String
    public let valuePattern: String
    public let urlTemplate: String
}
