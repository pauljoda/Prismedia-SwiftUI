import Foundation

/// Reads worker activity and submits explicit job-control operations.
public protocol AdministrativeJobServicing: Sendable {
    func jobs() async throws -> AdministrativeJobListResponse
    func createJob(type: String) async throws -> AdministrativeJobRun
    func cancelJob(id: UUID) async throws -> Int
    func cancelJobs(type: String?) async throws -> Int
    func clearFailures(type: String?) async throws -> Int
}
