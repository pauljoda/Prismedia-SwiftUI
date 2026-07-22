import Foundation

public protocol EntityAcquisitionServicing: Sendable {
    func loadState(entityID: UUID) async throws -> EntityMonitorState
    func loadStates(entityIDs: [UUID]) async throws -> [EntityMonitorState]
    func latestAcquisition(entityID: UUID) async throws -> RequestActivityAcquisitionDetail?
    func startMonitor(entityID: UUID) async throws
    func pauseMonitor(id: UUID) async throws
    func resumeMonitor(id: UUID) async throws
    func searchAgain(acquisitionID: UUID) async throws
    func searchForRelease(entityID: UUID) async throws
    func syncContainer(entityID: UUID) async throws
    func searchMissingChildren(entityID: UUID) async throws -> EntityMissingChildrenSearchResponse
    func unmonitor(id: UUID) async throws -> Bool
}

extension EntityAcquisitionServicing {
    public func loadStates(entityIDs: [UUID]) async throws -> [EntityMonitorState] {
        var states: [EntityMonitorState] = []
        for entityID in entityIDs {
            try Task.checkCancellation()
            states.append(try await loadState(entityID: entityID))
        }
        return states
    }
}
