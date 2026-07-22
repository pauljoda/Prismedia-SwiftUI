import Foundation

struct EntityAcquisitionPanelState: Sendable {
    private(set) var phase: EntityAcquisitionPanelPhase = .loading
    private(set) var isMutating = false
    private(set) var mutationError: String?
    private(set) var refreshError: String?

    init() {}

    #if DEBUG
        init(
            previewPhase: EntityAcquisitionPanelPhase,
            isMutating: Bool = false,
            mutationError: String? = nil,
            refreshError: String? = nil
        ) {
            phase = previewPhase
            self.isMutating = isMutating
            self.mutationError = mutationError
            self.refreshError = refreshError
        }
    #endif

    var latestAcquisition: RequestActivityAcquisitionDetail? {
        guard case .content(let snapshot) = phase else { return nil }
        return snapshot.latestAcquisition
    }

    mutating func finishLoad(_ outcome: EntityAcquisitionLoadOutcome) {
        switch outcome {
        case .content(let snapshot):
            let nextPhase = EntityAcquisitionPanelPhase.content(snapshot)
            if phase != nextPhase { phase = nextPhase }
            refreshError = nil
        case .failure(let message):
            let nextPhase = EntityAcquisitionPanelPhase.failure(message)
            if phase != nextPhase { phase = nextPhase }
        case .cancelled:
            break
        }
    }

    /// Applies a background refresh. A transient poll failure keeps the last good
    /// content on screen instead of flipping the panel into the failure state.
    mutating func finishBackgroundLoad(_ outcome: EntityAcquisitionLoadOutcome) {
        switch outcome {
        case .content(let snapshot):
            let nextPhase = EntityAcquisitionPanelPhase.content(snapshot)
            if phase != nextPhase { phase = nextPhase }
            refreshError = nil
        case .failure(let message):
            if case .content = phase { return }
            let nextPhase = EntityAcquisitionPanelPhase.failure(message)
            if phase != nextPhase { phase = nextPhase }
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
        case .missingChildrenSearchCompleted:
            return .refresh
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

    @discardableResult
    mutating func finishMutationRefresh(_ outcome: EntityAcquisitionLoadOutcome) -> Bool {
        switch outcome {
        case .content(let snapshot):
            let nextPhase = EntityAcquisitionPanelPhase.content(snapshot)
            if phase != nextPhase { phase = nextPhase }
            refreshError = nil
            return true
        case .failure(let message):
            refreshError = message
            return false
        case .cancelled:
            return false
        }
    }

    mutating func dismissRefreshError() {
        refreshError = nil
    }
}
