import Foundation

struct PrismediaEntityAcquisitionService: EntityAcquisitionServicing {
    let client: PrismediaAPIClient

    func loadState(entityID: UUID) async throws -> EntityMonitorState {
        try await client.fetchEntityMonitorState(entityID: entityID)
    }

    func loadStates(entityIDs: [UUID]) async throws -> [EntityMonitorState] {
        try await client.fetchEntityMonitorStates(entityIDs: entityIDs)
    }

    func latestAcquisition(entityID: UUID) async throws -> RequestActivityAcquisitionDetail? {
        try await client.fetchRequestActivityAcquisition(forEntity: entityID)
    }

    func acquisitionBlocklist(entityID: UUID?) async throws -> [RequestActivityBlocklistEntry] {
        let entries = try await client.listRequestActivityBlocklist()
        guard let entityID else { return entries }
        return entries.filter { $0.entityID == entityID }
    }

    func clearAcquisitionBlocklist(entityID: UUID?, createdAfter: Date?) async throws -> Int {
        try await client.clearAcquisitionBlocklist(
            entityID: entityID,
            createdAfter: createdAfter
        ).removed
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

    func searchForRelease(entityID: UUID) async throws {
        try await client.commitEntityRequest(entityID: entityID)
    }

    func syncContainer(entityID: UUID) async throws {
        try await client.syncEntityContainer(entityID: entityID)
    }

    func searchMissingChildren(entityID: UUID) async throws -> EntityMissingChildrenSearchResponse {
        try await client.commitMissingChildren(entityID: entityID)
    }

    func unmonitor(id: UUID) async throws -> Bool {
        try await client.unmonitor(id: id).entityPruned
    }
}
