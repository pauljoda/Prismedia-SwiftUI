import Foundation

public protocol AccountServicing: Sendable {
    func updateProfile(displayName: String) async throws -> UserAccount
    func changePassword(currentPassword: String, newPassword: String) async throws
    func sessions() async throws -> [AccountSession]
    func revoke(sessionID: UUID) async throws
}
