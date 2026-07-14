import Foundation

public struct AdministrativePlugin: Decodable, Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let version: String
    public let installed: Bool
    public let enabled: Bool
    public let isNsfw: Bool
    public let supports: [AdministrativePluginSupport]
    public let auth: [AdministrativePluginAuthField]
    public let missingAuthKeys: [String]
    public let updateAvailable: Bool
    public let availableVersion: String?

    public init(
        id: String,
        name: String,
        version: String,
        installed: Bool,
        enabled: Bool,
        isNsfw: Bool,
        supports: [AdministrativePluginSupport],
        auth: [AdministrativePluginAuthField] = [],
        missingAuthKeys: [String],
        updateAvailable: Bool,
        availableVersion: String?
    ) {
        self.id = id
        self.name = name
        self.version = version
        self.installed = installed
        self.enabled = enabled
        self.isNsfw = isNsfw
        self.supports = supports
        self.auth = auth
        self.missingAuthKeys = missingAuthKeys
        self.updateAvailable = updateAvailable
        self.availableVersion = availableVersion
    }
}
