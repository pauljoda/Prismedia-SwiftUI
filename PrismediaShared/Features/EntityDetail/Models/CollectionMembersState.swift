import Foundation

/// View-owned value state for collection membership.
///
/// Requests are tied to both the collection identity and a generation so a
/// response from a previous detail page cannot replace the currently rendered
/// collection. Cancellation restores the phase that existed before the load,
/// which keeps an interrupted initial request retryable and preserves content
/// during an interrupted refresh.
struct CollectionMembersState: Equatable, Sendable {
    private(set) var phase: CollectionMembersPhase = .idle

    private var collectionID: UUID?
    private var generation = 0
    private var restorablePhase: CollectionMembersPhase = .idle

    mutating func beginLoad(
        collectionID: UUID,
        force: Bool = false
    ) -> CollectionMembersRequest? {
        if self.collectionID == collectionID, !force, phase != .idle {
            return nil
        }

        if self.collectionID != collectionID {
            restorablePhase = .idle
        }
        generation += 1
        self.collectionID = collectionID
        phase = .loading

        return CollectionMembersRequest(
            collectionID: collectionID,
            generation: generation
        )
    }

    mutating func finishLoad(
        _ outcome: CollectionMembersLoadOutcome,
        request: CollectionMembersRequest
    ) {
        guard request.collectionID == collectionID,
            request.generation == generation
        else { return }

        switch outcome {
        case .content(let members):
            phase = .content(CollectionMembersPresentation.members(from: members))
            restorablePhase = phase
        case .failure(let message):
            phase = .failure(message)
            restorablePhase = phase
        case .cancelled:
            phase = restorablePhase
        case .unavailable:
            phase = .failure("Collection membership is unavailable.")
            restorablePhase = phase
        }
    }

    mutating func reset() {
        guard collectionID != nil || phase != .idle else { return }
        generation += 1
        collectionID = nil
        phase = .idle
        restorablePhase = .idle
    }
}
