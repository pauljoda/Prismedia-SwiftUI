import Foundation

public struct DatabaseBackupService: DatabaseBackupServicing {
    private let client: PrismediaAPIClient

    public init(client: PrismediaAPIClient) { self.client = client }

    public func backups() async throws -> AdministrativeDatabaseBackupList {
        try await client.listAdministrativeDatabaseBackups()
    }
    public func create() async throws -> AdministrativeDatabaseBackup {
        try await client.createAdministrativeDatabaseBackup()
    }
    public func restore(id: UUID, confirmationText: String) async throws
        -> AdministrativeDatabaseRestoreScheduled
    {
        try await client.restoreAdministrativeDatabaseBackup(id: id, confirmationText: confirmationText)
    }
    public func restoreStatus() async throws -> AdministrativeDatabaseRestoreStatus {
        try await client.administrativeDatabaseRestoreStatus()
    }
}
