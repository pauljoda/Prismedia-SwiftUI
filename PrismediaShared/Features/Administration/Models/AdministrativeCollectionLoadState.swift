import Foundation

/// Retains a refreshed collection, clears items when its location changes, and rejects superseded reads.
struct AdministrativeCollectionLoadState<Item: Sendable>: Sendable {
    private(set) var items: [Item] = []
    private(set) var isLoading = true
    private(set) var errorMessage: String?
    private var generation = 0

    mutating func begin(clearingItems: Bool = false) -> Int {
        generation += 1
        if clearingItems { items = [] }
        isLoading = true
        errorMessage = nil
        return generation
    }

    mutating func succeed(_ items: [Item], request: Int, isCancelled: Bool = false) {
        guard request == generation else { return }
        isLoading = false
        guard !isCancelled else { return }
        self.items = items
        errorMessage = nil
    }

    mutating func fail(_ error: any Error, request: Int, isCancelled: Bool) {
        guard request == generation else { return }
        isLoading = false
        guard !isCancelled, !(error is CancellationError),
            (error as? URLError)?.code != .cancelled
        else { return }
        errorMessage = error.localizedDescription
    }
}
