import SwiftUI

/// Loads the television home shelves concurrently and returns one immutable
/// presentation snapshot. The view owns loading and refresh state.
@MainActor
public struct TVHomeUseCase: Sendable {
    private let loader: any TVHomeLoading

    public init(loader: any TVHomeLoading) {
        self.loader = loader
    }

    public func load() async -> TVHomeLoadResult {
        let loader = self.loader
        let outcomes = await withTaskGroup(of: TVHomeLoadOutcome.self) { group in
            for shelf in TVAppCatalog.homeShelves {
                group.addTask {
                    do {
                        return .success(id: shelf.id, items: try await loader.load(shelf: shelf))
                    } catch {
                        return .failure(id: shelf.id)
                    }
                }
            }

            var collected: [TVHomeLoadOutcome] = []
            for await outcome in group { collected.append(outcome) }
            return collected
        }

        var itemsByShelfID: [String: [EntityThumbnail]] = [:]
        var failedShelfIDs = Set<String>()
        for outcome in outcomes {
            switch outcome {
            case .success(let id, let items):
                itemsByShelfID[id] = items
            case .failure(let id):
                failedShelfIDs.insert(id)
            }
        }

        return TVHomeLoadResult(
            snapshot: TVHomeSnapshot(itemsByShelfID: itemsByShelfID),
            failedShelfIDs: failedShelfIDs
        )
    }
}
