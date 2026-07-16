import Foundation

public protocol DatabaseBackupServicing: Sendable {
    func backups() async throws -> AdministrativeDatabaseBackupList
    func create() async throws -> AdministrativeDatabaseBackup
    func restore(id: UUID, confirmationText: String) async throws -> AdministrativeDatabaseRestoreScheduled
    func restoreStatus() async throws -> AdministrativeDatabaseRestoreStatus
}
