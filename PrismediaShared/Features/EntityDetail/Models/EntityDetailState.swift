import Foundation

/// Value state owned by `EntityDetailView`.
///
/// Request generations live with the rendered state so a response can only
/// update the request that produced it. The service remains stateless and can
/// therefore be shared by previews and tests without hidden lifetime rules.
struct EntityDetailState: Sendable {
    private(set) var phase: EntityDetailPhase = .loading
    private(set) var isMutating = false
    private(set) var mutationErrorMessage: String?

    private var generation = 0

    var detail: EntityDetail? {
        guard case .content(let detail) = phase else { return nil }
        return detail
    }

    mutating func beginLoad() -> EntityDetailRequest? {
        guard !isMutating else { return nil }
        let request = nextRequest()
        phase = .loading
        mutationErrorMessage = nil
        return request
    }

    mutating func finishLoad(
        _ outcome: EntityDetailLoadOutcome,
        request: EntityDetailRequest
    ) {
        guard isCurrent(request) else { return }

        switch outcome {
        case .content(let detail):
            phase = .content(detail)
        case .failure(let message):
            phase = .failure(message)
        case .cancelled:
            break
        }
    }

    mutating func beginMutation(canMutate: Bool) -> EntityDetailRequest? {
        guard canMutate, !isMutating, detail != nil else { return nil }
        let request = nextRequest()
        isMutating = true
        mutationErrorMessage = nil
        return request
    }

    /// Publishes the narrow write response immediately while a full refresh is
    /// still in flight. Returns whether the write was accepted for this request.
    @discardableResult
    mutating func finishMutationSave(
        _ outcome: EntityDetailMutationOutcome,
        request: EntityDetailRequest
    ) -> Bool {
        guard isCurrent(request) else { return false }

        switch outcome {
        case .content(let response):
            guard let current = detail else {
                isMutating = false
                return false
            }
            phase = .content(current.mergingUserMetadata(from: response))
            return true
        case .failure(let message):
            isMutating = false
            mutationErrorMessage = message
            return false
        case .cancelled, .unavailable:
            isMutating = false
            return false
        }
    }

    mutating func finishMutationRefresh(
        _ outcome: EntityDetailLoadOutcome,
        request: EntityDetailRequest
    ) {
        guard isCurrent(request) else { return }
        isMutating = false

        switch outcome {
        case .content(let detail):
            phase = .content(detail)
        case .failure:
            mutationErrorMessage = "The change was saved, but the latest details couldn’t be refreshed."
        case .cancelled:
            break
        }
    }

    mutating func dismissMutationError() {
        mutationErrorMessage = nil
    }

    mutating func replaceContent(with detail: EntityDetail) {
        guard self.detail?.id == detail.id else { return }
        generation += 1
        phase = .content(detail)
    }

    var favoriteToggleMutation: EntityDetailMutation? {
        guard let flags = currentFlags else { return nil }
        return .favorite(!(flags.isFavorite ?? false))
    }

    var organizedToggleMutation: EntityDetailMutation? {
        guard let flags = currentFlags else { return nil }
        return .organized(!(flags.isOrganized ?? false))
    }

    private var currentFlags: EntityFlagsCapability? {
        detail?.capability()
    }

    private mutating func nextRequest() -> EntityDetailRequest {
        generation += 1
        return EntityDetailRequest(generation: generation)
    }

    private func isCurrent(_ request: EntityDetailRequest) -> Bool {
        request.generation == generation
    }
}
