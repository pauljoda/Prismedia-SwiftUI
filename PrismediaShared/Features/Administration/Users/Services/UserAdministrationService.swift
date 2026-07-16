import Foundation

public struct UserAdministrationService: UserAdministrationServicing {
    private let client: PrismediaAPIClient

    public init(client: PrismediaAPIClient) { self.client = client }

    public func users() async throws -> [UserAccount] { try await client.listAdministrativeUsers() }
    public func create(_ mutation: AdministrativeUserCreateMutation) async throws -> UserAccount {
        try await client.createAdministrativeUser(mutation)
    }
    public func update(id: UUID, mutation: AdministrativeUserUpdateMutation) async throws -> UserAccount {
        try await client.updateAdministrativeUser(id: id, mutation: mutation)
    }
    public func resetPassword(id: UUID, newPassword: String) async throws {
        try await client.resetAdministrativeUserPassword(id: id, newPassword: newPassword)
    }
    public func replaceLibraryAccess(id: UUID, rootIDs: [UUID]) async throws {
        try await client.replaceAdministrativeUserLibraryAccess(userID: id, rootIDs: rootIDs)
    }
    public func delete(id: UUID) async throws { try await client.deleteAdministrativeUser(id: id) }
}
