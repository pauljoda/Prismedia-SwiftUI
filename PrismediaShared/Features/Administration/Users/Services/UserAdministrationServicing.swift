import Foundation

public protocol UserAdministrationServicing: Sendable {
    func users() async throws -> [UserAccount]
    func create(_ mutation: AdministrativeUserCreateMutation) async throws -> UserAccount
    func update(id: UUID, mutation: AdministrativeUserUpdateMutation) async throws -> UserAccount
    func resetPassword(id: UUID, newPassword: String) async throws
    func replaceLibraryAccess(id: UUID, rootIDs: [UUID]) async throws
    func delete(id: UUID) async throws
}
