import Foundation

@MainActor
struct EntityAcquisitionService {
    private let port: any EntityAcquisitionServicing

    init(port: any EntityAcquisitionServicing) {
        self.port = port
    }

    func load(entityID: UUID) async -> EntityAcquisitionLoadOutcome {
        do {
            let state = try await port.loadState(entityID: entityID)
            // Best-effort like the web: a transient acquisition-read failure keeps the
            // monitor state usable instead of failing the whole panel.
            let latestAcquisition = (try? await port.latestAcquisition(entityID: entityID)) ?? nil
            guard !Task.isCancelled else { return .cancelled }
            return .content(
                EntityAcquisitionPanelSnapshot(state: state, latestAcquisition: latestAcquisition)
            )
        } catch is CancellationError {
            return .cancelled
        } catch {
            guard !Task.isCancelled else { return .cancelled }
            return .failure(error.localizedDescription)
        }
    }

    func perform(_ command: EntityAcquisitionCommand) async -> EntityAcquisitionMutationOutcome {
        do {
            let outcome = try await execute(command)
            guard !Task.isCancelled else { return .cancelled }
            return outcome
        } catch is CancellationError {
            return .cancelled
        } catch {
            guard !Task.isCancelled else { return .cancelled }
            return .failure(error.localizedDescription)
        }
    }

    func loadStates(entityIDs: [UUID]) async throws -> [EntityMonitorState] {
        try await port.loadStates(entityIDs: entityIDs)
    }

    private func execute(
        _ command: EntityAcquisitionCommand
    ) async throws -> EntityAcquisitionMutationOutcome {
        switch command {
        case .start(let entityID):
            try await port.startMonitor(entityID: entityID)
        case .pause(let id):
            try await port.pauseMonitor(id: id)
        case .resume(let id):
            try await port.resumeMonitor(id: id)
        case .searchAgain(let acquisitionID):
            try await port.searchAgain(acquisitionID: acquisitionID)
        case .searchForRelease(let entityID):
            try await port.searchForRelease(entityID: entityID)
        case .syncContainer(let entityID):
            try await port.syncContainer(entityID: entityID)
        case .searchMissingChildren(let entityID):
            let result = try await port.searchMissingChildren(entityID: entityID)
            return .missingChildrenSearchCompleted(result)
        case .unmonitor(let id):
            return .completed(entityPruned: try await port.unmonitor(id: id))
        }
        return .completed(entityPruned: false)
    }
}
