import Foundation

struct EntityAcquisitionPanelState: Sendable {
    private(set) var phase: EntityAcquisitionPanelPhase = .loading
    private(set) var isMutating = false
    private(set) var mutationError: String?

    mutating func finishLoad(_ outcome: EntityAcquisitionLoadOutcome) {
        switch outcome {
        case .content(let snapshot):
            phase = .content(snapshot)
        case .failure(let message):
            phase = .failure(message)
        case .cancelled:
            break
        }
    }

    mutating func beginMutation() -> Bool {
        guard !isMutating else { return false }
        isMutating = true
        mutationError = nil
        return true
    }

    mutating func finishMutation(
        _ outcome: EntityAcquisitionMutationOutcome
    ) -> EntityAcquisitionPanelEffect {
        isMutating = false
        switch outcome {
        case .completed(let entityPruned):
            return entityPruned ? .entityPruned : .refresh
        case .failure(let message):
            mutationError = message
            return .none
        case .cancelled:
            return .none
        }
    }

    mutating func dismissMutationError() {
        mutationError = nil
    }
}
