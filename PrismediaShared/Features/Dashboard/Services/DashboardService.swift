import Foundation

/// Stateless dashboard use case. It coordinates independent shelves and
/// returns a complete value snapshot for the view to own.
@MainActor
public struct DashboardService {
    private let loader: any DashboardLoading

    public init(loader: any DashboardLoading) {
        self.loader = loader
    }

    public func load() async -> DashboardSnapshot {
        let loader = self.loader
        var snapshot = DashboardSnapshot(state: .loading)
        var loadedContinueItems: [EntityThumbnail] = []

        await withTaskGroup(of: DashboardLoadResult.self) { group in
            group.addTask {
                await .continueItems(Self.loadSafely(loader, DashboardCatalog.continueQuery))
            }
            group.addTask {
                await .recentItems(Self.loadSafely(loader, DashboardCatalog.recentQuery))
            }
            for definition in DashboardCatalog.sections {
                group.addTask {
                    await .section(
                        definition,
                        Self.loadSafely(loader, definition.query)
                    )
                }
            }

            var loadedSections: [String: DashboardSection] = [:]
            for await result in group {
                switch result {
                case .continueItems(let items):
                    loadedContinueItems = items
                case .recentItems(let items):
                    snapshot.recentItems = items
                case .section(let definition, let items):
                    loadedSections[definition.id] = DashboardSection(
                        definition: definition,
                        items: items
                    )
                }
            }
            snapshot.sections = DashboardCatalog.sections.compactMap {
                loadedSections[$0.id]
            }
        }

        snapshot.featuredItems = DashboardFeaturedSelection.items(
            playbackHistory: loadedContinueItems + snapshot.recentItems,
            catalogSources: snapshot.sections.map(\.items)
        )
        snapshot.continueItems = loadedContinueItems

        snapshot.state = snapshot.hasContent ? .content : .empty
        return snapshot
    }

    nonisolated private static func loadSafely(
        _ loader: any DashboardLoading,
        _ query: EntityListQuery
    ) async -> [EntityThumbnail] {
        (try? await loader.load(query, limit: DashboardCatalog.itemLimit).items) ?? []
    }
}
