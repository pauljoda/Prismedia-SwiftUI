import Foundation

@MainActor
public struct FavoritesService {
    private let loader: any FavoritesLoading

    public init(loader: any FavoritesLoading) {
        self.loader = loader
    }

    public func load() async -> FavoritesSnapshot {
        let items = (try? await loader.load(
            FavoritesCatalog.overviewQuery,
            limit: FavoritesCatalog.overviewLimit
        ).items) ?? []
        let sections = FavoritesCatalog.sections.map { definition in
            FavoritesSection(
                definition: definition,
                items: Array(
                    items
                        .lazy
                        .filter { $0.kind == definition.kind }
                        .prefix(FavoritesCatalog.itemLimit)
                )
            )
        }
        return FavoritesSnapshot(
            sections: sections,
            state: sections.contains { !$0.items.isEmpty } ? .content : .empty
        )
    }
}
