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
            guard !Task.isCancelled else { return .cancelled }
            return .content(state)
        } catch is CancellationError {
            return .cancelled
        } catch {
            guard !Task.isCancelled else { return .cancelled }
            return .failure(error.localizedDescription)
        }
    }

    func perform(_ command: EntityAcquisitionCommand) async -> EntityAcquisitionMutationOutcome {
        do {
            let entityPruned = try await execute(command)
            guard !Task.isCancelled else { return .cancelled }
            return .completed(entityPruned: entityPruned)
        } catch is CancellationError {
            return .cancelled
        } catch {
            guard !Task.isCancelled else { return .cancelled }
            return .failure(error.localizedDescription)
        }
    }

    private func execute(_ command: EntityAcquisitionCommand) async throws -> Bool {
        switch command {
        case .start(let entityID):
            try await port.startMonitor(entityID: entityID)
        case .pause(let id):
            try await port.pauseMonitor(id: id)
        case .resume(let id):
            try await port.resumeMonitor(id: id)
        case .searchAgain(let acquisitionID):
            try await port.searchAgain(acquisitionID: acquisitionID)
        case .unmonitor(let id):
            return try await port.unmonitor(id: id)
        }
        return false
    }
}
