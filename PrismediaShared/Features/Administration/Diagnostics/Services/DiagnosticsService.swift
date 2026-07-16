import Foundation

public struct DiagnosticsService: DiagnosticsServicing {
    private let client: PrismediaAPIClient

    public init(client: PrismediaAPIClient) { self.client = client }

    public func snapshot() async throws -> AdministrativeDiagnosticsSnapshot {
        async let health = client.health()
        async let worker = client.administrativeWorkerHealth()
        async let backups = client.listAdministrativeDatabaseBackups()
        async let restore = client.administrativeDatabaseRestoreStatus()
        return try await AdministrativeDiagnosticsSnapshot(
            health: health,
            worker: worker,
            backups: backups,
            restore: restore
        )
    }

    public func rebuildPreviews() async throws -> AdministrativeBulkJobResponse {
        try await client.rebuildAdministrativePreviews()
    }

    public func backfillFingerprints() async throws -> AdministrativeBulkJobResponse {
        try await client.backfillAdministrativeFingerprints()
    }
}
