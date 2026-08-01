import Foundation

public struct AdministrativeUserUpdateMutation: Encodable, Hashable, Sendable {
    public let username: String?
    public let displayName: String?
    public let role: UserRole?
    public let allowNsfw: Bool?
    public let canCreateLibraries: Bool?
    public let enabled: Bool?

    public init(
        username: String? = nil,
        displayName: String? = nil,
        role: UserRole? = nil,
        allowNsfw: Bool? = nil,
        canCreateLibraries: Bool? = nil,
        enabled: Bool? = nil
    ) {
        self.username = username
        self.displayName = displayName
        self.role = role
        self.allowNsfw = allowNsfw
        self.canCreateLibraries = canCreateLibraries
        self.enabled = enabled
    }
}
