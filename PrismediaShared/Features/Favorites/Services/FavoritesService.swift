import Foundation

@MainActor
public struct FavoritesService {
    private let loader: any FavoritesLoading

    public init(loader: any FavoritesLoading) {
        self.loader = loader
    }

    public func load() async -> FavoritesSnapshot {
        let loader = self.loader
        var loadedSections: [String: FavoritesSection] = [:]

        await withTaskGroup(of: FavoritesSection.self) { group in
            for definition in FavoritesCatalog.sections {
                group.addTask {
                    let items =
                        (try? await loader.load(
                            definition.query,
                            limit: FavoritesCatalog.itemLimit
                        ).items) ?? []
                    return FavoritesSection(definition: definition, items: items)
                }
            }

            for await section in group {
                loadedSections[section.id] = section
            }
        }

        let sections = FavoritesCatalog.sections.compactMap { definition in
            loadedSections[definition.id]
        }
        return FavoritesSnapshot(
            sections: sections,
            state: sections.contains { !$0.items.isEmpty } ? .content : .empty
        )
    }
}
