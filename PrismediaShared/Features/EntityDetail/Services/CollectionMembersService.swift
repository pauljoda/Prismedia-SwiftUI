import Foundation

/// Focused collection-membership use case. It owns I/O, while the detail view
/// owns request identity and presentation state through `CollectionMembersState`.
@MainActor
struct CollectionMembersService {
    private let loader: (any CollectionItemsLoading)?

    init(loader: (any CollectionItemsLoading)?) {
        self.loader = loader
    }

    func load(collectionID: UUID) async -> CollectionMembersLoadOutcome {
        guard let loader else { return .unavailable }

        do {
            let members = try await loader.loadCollectionItems(collectionID: collectionID)
            guard !Task.isCancelled else { return .cancelled }
            return .content(members)
        } catch is CancellationError {
            return .cancelled
        } catch {
            guard !Task.isCancelled else { return .cancelled }
            return .failure(error.localizedDescription)
        }
    }
}
