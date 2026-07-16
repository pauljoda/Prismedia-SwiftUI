import Foundation

public struct AccountService: AccountServicing {
    private let client: PrismediaAPIClient

    public init(client: PrismediaAPIClient) { self.client = client }

    public func updateProfile(displayName: String) async throws -> UserAccount {
        try await client.updateOwnProfile(displayName: displayName)
    }

    public func changePassword(currentPassword: String, newPassword: String) async throws {
        try await client.changeOwnPassword(currentPassword: currentPassword, newPassword: newPassword)
    }

    public func sessions() async throws -> [AccountSession] { try await client.listOwnSessions() }

    public func revoke(sessionID: UUID) async throws { try await client.revokeOwnSession(id: sessionID) }
}
