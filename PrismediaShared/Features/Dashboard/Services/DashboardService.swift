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

        let allItemGroups = [loadedContinueItems, snapshot.recentItems]
            + snapshot.sections.map(\.items)
        let movieIDs = Self.movieParentIDs(in: allItemGroups)
        let movies = (try? await loader.loadThumbnails(ids: movieIDs)) ?? []
        let moviesByID = Dictionary(uniqueKeysWithValues: movies.map { ($0.id, $0) })
        loadedContinueItems = Self.applyingMoviePosters(to: loadedContinueItems, moviesByID: moviesByID)
        snapshot.recentItems = Self.applyingMoviePosters(to: snapshot.recentItems, moviesByID: moviesByID)
        snapshot.sections = snapshot.sections.map { section in
            DashboardSection(
                definition: section.definition,
                items: Self.applyingMoviePosters(to: section.items, moviesByID: moviesByID)
            )
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

    nonisolated private static func movieParentIDs(in itemGroups: [[EntityThumbnail]]) -> [UUID] {
        var seen = Set<UUID>()
        return itemGroups.flatMap { $0 }.compactMap { item in
            guard item.kind == .video,
                item.parentKind == .movie,
                let parentID = item.parentEntityID,
                seen.insert(parentID).inserted
            else { return nil }
            return parentID
        }
    }

    nonisolated private static func applyingMoviePosters(
        to items: [EntityThumbnail],
        moviesByID: [UUID: EntityThumbnail]
    ) -> [EntityThumbnail] {
        items.map { item in
            guard item.kind == .video,
                item.parentKind == .movie,
                let parentID = item.parentEntityID,
                let movie = moviesByID[parentID]
            else { return item }
            return item.replacingCoverArtwork(with: movie)
        }
    }
}
