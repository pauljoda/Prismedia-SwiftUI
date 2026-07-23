import Foundation

public protocol AcquisitionBlocklistServicing: Sendable {
    func acquisitionBlocklist(entityID: UUID?) async throws -> [RequestActivityBlocklistEntry]
    func clearAcquisitionBlocklist(entityID: UUID?, createdAfter: Date?) async throws -> Int
}
