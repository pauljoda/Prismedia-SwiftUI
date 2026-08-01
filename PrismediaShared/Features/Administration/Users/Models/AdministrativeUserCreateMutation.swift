import Foundation

public struct AdministrativeUserCreateMutation: Encodable, Hashable, Sendable {
    public let username: String
    public let password: String
    public let displayName: String?
    public let role: UserRole
    public let allowNsfw: Bool
    public let canCreateLibraries: Bool
    public let enabled: Bool

    public init(
        username: String,
        password: String,
        displayName: String? = nil,
        role: UserRole = .member,
        allowNsfw: Bool = false,
        canCreateLibraries: Bool = false,
        enabled: Bool = true
    ) {
        self.username = username
        self.password = password
        self.displayName = displayName
        self.role = role
        self.allowNsfw = allowNsfw
        self.canCreateLibraries = canCreateLibraries
        self.enabled = enabled
    }
}
