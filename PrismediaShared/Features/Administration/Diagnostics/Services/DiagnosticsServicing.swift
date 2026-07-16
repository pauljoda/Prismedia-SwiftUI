import Foundation

public protocol DiagnosticsServicing: Sendable {
    func snapshot() async throws -> AdministrativeDiagnosticsSnapshot
    func rebuildPreviews() async throws -> AdministrativeBulkJobResponse
    func backfillFingerprints() async throws -> AdministrativeBulkJobResponse
}
