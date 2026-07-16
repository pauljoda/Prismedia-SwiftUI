import Foundation

public struct AdministrativeDiagnosticsSnapshot: Hashable, Sendable {
    public let health: HealthResponse
    public let worker: AdministrativeWorkerHealth
    public let backups: AdministrativeDatabaseBackupList
    public let restore: AdministrativeDatabaseRestoreStatus

    public init(
        health: HealthResponse,
        worker: AdministrativeWorkerHealth,
        backups: AdministrativeDatabaseBackupList,
        restore: AdministrativeDatabaseRestoreStatus
    ) {
        self.health = health
        self.worker = worker
        self.backups = backups
        self.restore = restore
    }
}
