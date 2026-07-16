import Foundation

public struct UserAccount: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public let username: String
    public let displayName: String
    public let role: UserRole
    public let allowSfw: Bool
    public let allowNsfw: Bool
    public let canCreateLibraries: Bool
    public let enabled: Bool
    public let lastLoginAt: Date?
    public let createdAt: Date?
    public let updatedAt: Date?
    public let libraryRootIDs: [UUID]?

    public var isAdmin: Bool {
        role == .admin
    }

    public init(
        id: UUID,
        username: String,
        displayName: String,
        role: UserRole,
        allowSfw: Bool = true,
        allowNsfw: Bool = false,
        canCreateLibraries: Bool = false,
        enabled: Bool = true,
        lastLoginAt: Date? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        libraryRootIDs: [UUID]? = nil
    ) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.role = role
        self.allowSfw = allowSfw
        self.allowNsfw = allowNsfw
        self.canCreateLibraries = canCreateLibraries
        self.enabled = enabled
        self.lastLoginAt = lastLoginAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.libraryRootIDs = libraryRootIDs
    }
}
