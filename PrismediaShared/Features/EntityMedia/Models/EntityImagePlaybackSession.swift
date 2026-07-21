import Foundation
import Observation

@Observable
@MainActor
public final class EntityImagePlaybackSession {
    public private(set) var activeEntityID: UUID?
    public private(set) var isMuted = true
    private var activeClaimID: UUID?

    public init() {}

    public func activate(_ entityID: UUID) {
        activate(entityID, claimID: entityID)
    }

    public func activate(_ entityID: UUID, claimID: UUID) {
        activeEntityID = entityID
        activeClaimID = claimID
    }

    public func deactivate(_ entityID: UUID) {
        guard activeEntityID == entityID else { return }
        activeEntityID = nil
        activeClaimID = nil
    }

    public func deactivate(_ entityID: UUID, claimID: UUID) {
        guard activeEntityID == entityID, activeClaimID == claimID else { return }
        activeEntityID = nil
        activeClaimID = nil
    }

    public func toggleMute() {
        isMuted.toggle()
    }

    public func toggleMute(entityID: UUID, claimID: UUID) {
        if isMuted || activeClaimID != claimID {
            activate(entityID, claimID: claimID)
            isMuted = false
        } else {
            isMuted = true
        }
    }

    public func isMuted(for claimID: UUID) -> Bool {
        isMuted || activeClaimID != claimID
    }

    public func reset() {
        activeEntityID = nil
        activeClaimID = nil
        isMuted = true
    }
}
