import Foundation

/// Keeps exact rendition ownership and request progress together for native Book details.
struct EntityManagedBookRenditionPresentation: Identifiable {
    let provenance: EntityExternalBookRenditionProvenance

    var id: UUID { provenance.holding.holdingID }

    /// A removed or cancelled request retains the manager's ownership fence until release.
    var isManagerOwned: Bool {
        provenance.holding.status != .released
            && provenance.request.phase != .ownershipReleased
    }

    var state: EntityManagedBookRenditionState {
        let phase = provenance.request.phase
        let tracking = provenance.holding.status

        if tracking == .needsReview || tracking == .stale || tracking == .removed
            || phase == .creationUncertain || phase == .remoteRemoved || phase == .rejected
        { return .needsReview }
        if phase == .ownershipReleased || tracking == .released { return .released }
        if tracking == .releasePending { return .releasing }
        if phase == .cancelled { return .cancelled }
        if phase == .completed { return .completed }
        if phase == .pendingCreation || tracking == .pending { return .starting }
        if phase == .awaitingFiles || tracking == .waitingForFiles { return .waitingForFiles }
        if tracking == .tracking { return .tracking }
        return .updating
    }

    var reviewProblem: String? {
        guard state == .needsReview,
            let problem = provenance.request.problem?.trimmingCharacters(in: .whitespacesAndNewlines),
            !problem.isEmpty
        else { return nil }
        return problem
    }
}
