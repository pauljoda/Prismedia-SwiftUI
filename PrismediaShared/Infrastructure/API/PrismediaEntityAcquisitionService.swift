import Foundation

struct PrismediaEntityAcquisitionService: EntityAcquisitionServicing {
    let client: PrismediaAPIClient

    func loadState(entityID: UUID) async throws -> EntityMonitorState {
        try await client.fetchEntityMonitorState(entityID: entityID)
    }

    func startMonitor(entityID: UUID) async throws {
        try await client.startEntityMonitor(entityID: entityID)
    }

    func pauseMonitor(id: UUID) async throws {
        try await client.pauseMonitor(id: id)
    }

    func resumeMonitor(id: UUID) async throws {
        try await client.resumeMonitor(id: id)
    }

    func searchAgain(acquisitionID: UUID) async throws {
        try await client.searchAcquisitionAgain(id: acquisitionID)
    }

    func unmonitor(id: UUID) async throws -> Bool {
        try await client.unmonitor(id: id).entityPruned
    }
}
