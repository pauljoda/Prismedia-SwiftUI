import Foundation

/// Small detail-read boundary used by the native detail feature and its tests.

/// Collection membership boundary kept separate from generic entity detail reads.

/// Narrow write boundary for detail-level user metadata controls.

/// Focused Entity Detail use case. It performs I/O but owns no presentation
/// state; the view-owned `EntityDetailState` decides whether results are current.
@MainActor
struct EntityDetailService {
    private let loader: any EntityDetailLoading
    private let mutator: (any EntityDetailMutating)?

    init(
        loader: any EntityDetailLoading,
        mutator: (any EntityDetailMutating)?
    ) {
        self.loader = loader
        self.mutator = mutator
    }

    var canMutate: Bool {
        mutator != nil
    }

    func load(id: UUID) async -> EntityDetailLoadOutcome {
        await load(id: id, kind: nil)
    }

    func load(id: UUID, kind: EntityKind?) async -> EntityDetailLoadOutcome {
        do {
            let detail: EntityDetail
            if let kind {
                detail = try await loader.loadEntity(id: id, kind: kind)
            } else {
                detail = try await loader.loadEntity(id: id)
            }
            guard !Task.isCancelled else { return .cancelled }
            return .content(detail)
        } catch is CancellationError {
            return .cancelled
        } catch {
            guard !Task.isCancelled else { return .cancelled }
            return .failure(error.localizedDescription)
        }
    }

    func save(
        _ mutation: EntityDetailMutation,
        id: UUID
    ) async -> EntityDetailMutationOutcome {
        guard let mutator else {
            return .unavailable
        }

        do {
            let detail = try await update(mutation, id: id, using: mutator)
            guard !Task.isCancelled else { return .cancelled }
            return .content(detail)
        } catch is CancellationError {
            return .cancelled
        } catch {
            guard !Task.isCancelled else { return .cancelled }
            return .failure(error.localizedDescription)
        }
    }

    private func update(
        _ mutation: EntityDetailMutation,
        id: UUID,
        using mutator: any EntityDetailMutating
    ) async throws -> EntityDetail {
        switch mutation {
        case .rating(let value):
            try await mutator.updateRating(id: id, value: value)
        case .favorite(let isFavorite):
            try await mutator.updateFlags(
                id: id,
                isFavorite: isFavorite,
                isNsfw: nil,
                isOrganized: nil
            )
        case .organized(let isOrganized):
            try await mutator.updateFlags(
                id: id,
                isFavorite: nil,
                isNsfw: nil,
                isOrganized: isOrganized
            )
        }
    }
}
