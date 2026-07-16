import Foundation

extension PrismediaAPIClient {
    public func updateOwnProfile(displayName: String) async throws -> UserAccount {
        try await send(
            UserAccount.self,
            path: "/api/auth/me",
            method: "PATCH",
            body: AccountProfileUpdateRequest(displayName: displayName)
        )
    }

    public func changeOwnPassword(currentPassword: String, newPassword: String) async throws {
        try await sendExpectingNoContent(
            path: "/api/auth/password",
            method: "POST",
            body: AccountPasswordChangeRequest(currentPassword: currentPassword, newPassword: newPassword)
        )
    }

    public func listOwnSessions() async throws -> [AccountSession] {
        try await send(AccountSessionsResponse.self, path: "/api/auth/sessions").items
    }

    public func revokeOwnSession(id: UUID) async throws {
        try await sendExpectingNoContent(
            path: "/api/auth/sessions/\(id.uuidString.lowercased())",
            method: "DELETE"
        )
    }

    public func browseAdministrativeLibraryPath(_ path: String?) async throws
        -> AdministrativeLibraryBrowseResponse
    {
        try await send(
            AdministrativeLibraryBrowseResponse.self,
            path: "/api/libraries/browse",
            queryItems: path.map { [URLQueryItem(name: "path", value: $0)] } ?? []
        )
    }

    public func createAdministrativeLibraryRoot(_ mutation: AdministrativeLibraryRootMutation) async throws
        -> AdministrativeLibraryRoot
    {
        try await send(AdministrativeLibraryRoot.self, path: "/api/libraries", method: "POST", body: mutation)
    }

    public func updateAdministrativeLibraryRoot(
        id: UUID,
        mutation: AdministrativeLibraryRootMutation
    ) async throws -> AdministrativeLibraryRoot {
        try await send(
            AdministrativeLibraryRoot.self,
            path: "/api/libraries/\(id.uuidString.lowercased())",
            method: "PATCH",
            body: mutation
        )
    }

    public func replaceAdministrativeLibraryAccess(rootID: UUID, userIDs: [UUID]) async throws {
        try await sendExpectingNoContent(
            path: "/api/libraries/\(rootID.uuidString.lowercased())/access",
            method: "PUT",
            body: AdministrativeLibraryAccessRequest(userIDs: userIDs)
        )
    }

    public func deleteAdministrativeLibraryRoot(id: UUID) async throws {
        _ = try await send(
            AdministrativeDeleteResponse.self,
            path: "/api/libraries/\(id.uuidString.lowercased())",
            method: "DELETE"
        )
    }

    public func listAdministrativeUsers() async throws -> [UserAccount] {
        try await send(AdministrativeUsersResponse.self, path: "/api/users").items
    }

    public func createAdministrativeUser(_ mutation: AdministrativeUserCreateMutation) async throws -> UserAccount {
        try await send(UserAccount.self, path: "/api/users", method: "POST", body: mutation)
    }

    public func updateAdministrativeUser(id: UUID, mutation: AdministrativeUserUpdateMutation) async throws
        -> UserAccount
    {
        try await send(
            UserAccount.self,
            path: "/api/users/\(id.uuidString.lowercased())",
            method: "PATCH",
            body: mutation
        )
    }

    public func resetAdministrativeUserPassword(id: UUID, newPassword: String) async throws {
        try await sendExpectingNoContent(
            path: "/api/users/\(id.uuidString.lowercased())/password",
            method: "POST",
            body: AdministrativeUserPasswordRequest(newPassword: newPassword)
        )
    }

    public func replaceAdministrativeUserLibraryAccess(userID: UUID, rootIDs: [UUID]) async throws {
        try await sendExpectingNoContent(
            path: "/api/users/\(userID.uuidString.lowercased())/library-access",
            method: "PUT",
            body: AdministrativeUserLibraryAccessRequest(libraryRootIDs: rootIDs)
        )
    }

    public func deleteAdministrativeUser(id: UUID) async throws {
        try await sendExpectingNoContent(path: "/api/users/\(id.uuidString.lowercased())", method: "DELETE")
    }

    public func administrativeWorkerHealth() async throws -> AdministrativeWorkerHealth {
        try await send(AdministrativeWorkerHealth.self, path: "/api/health/worker")
    }

    public func backfillAdministrativeFingerprints() async throws -> AdministrativeBulkJobResponse {
        try await send(
            AdministrativeBulkJobResponse.self,
            path: "/api/jobs/backfill-fingerprints",
            method: "POST"
        )
    }

    public func listAdministrativeDatabaseBackups() async throws -> AdministrativeDatabaseBackupList {
        try await send(AdministrativeDatabaseBackupList.self, path: "/api/settings/database-backups")
    }

    public func restoreAdministrativeDatabaseBackup(id: UUID, confirmationText: String) async throws
        -> AdministrativeDatabaseRestoreScheduled
    {
        try await send(
            AdministrativeDatabaseRestoreScheduled.self,
            path: "/api/settings/database-backups/restore",
            method: "POST",
            body: AdministrativeDatabaseRestoreRequest(backupID: id, confirmationText: confirmationText)
        )
    }

    public func administrativeDatabaseRestoreStatus() async throws -> AdministrativeDatabaseRestoreStatus {
        try await send(AdministrativeDatabaseRestoreStatus.self, path: "/api/health/database-restore")
    }
}
