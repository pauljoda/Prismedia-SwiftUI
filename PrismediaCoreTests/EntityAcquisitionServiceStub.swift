import Foundation

@testable import PrismediaCore

actor EntityAcquisitionServiceStub: EntityAcquisitionServicing {
    private(set) var commands: [EntityAcquisitionCommand] = []
    private let state: EntityMonitorState
    private let entityPruned: Bool
    private let error: Error?

    init(
        state: EntityMonitorState,
        entityPruned: Bool = false,
        error: Error? = nil
    ) {
        self.state = state
        self.entityPruned = entityPruned
        self.error = error
    }

    func loadState(entityID _: UUID) async throws -> EntityMonitorState {
        try throwIfNeeded()
        return state
    }

    func startMonitor(entityID: UUID) async throws {
        commands.append(.start(entityID))
        try throwIfNeeded()
    }

    func pauseMonitor(id: UUID) async throws {
        commands.append(.pause(id))
        try throwIfNeeded()
    }

    func resumeMonitor(id: UUID) async throws {
        commands.append(.resume(id))
        try throwIfNeeded()
    }

    func searchAgain(acquisitionID: UUID) async throws {
        commands.append(.searchAgain(acquisitionID))
        try throwIfNeeded()
    }

    func unmonitor(id: UUID) async throws -> Bool {
        commands.append(.unmonitor(id))
        try throwIfNeeded()
        return entityPruned
    }

    private func throwIfNeeded() throws {
        if let error { throw error }
    }
}
