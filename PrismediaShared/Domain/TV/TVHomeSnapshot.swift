import Foundation

public struct TVHomeSnapshot: Equatable, Sendable {
    private let itemsByShelfID: [String: [EntityThumbnail]]

    public init(itemsByShelfID: [String: [EntityThumbnail]] = [:]) {
        self.itemsByShelfID = itemsByShelfID
    }

    public var hero: EntityThumbnail? {
        heroItems.first
    }

    public var heroItems: [EntityThumbnail] {
        var seen = Set<UUID>()
        let candidates = ["in-progress", "movies", "series"]
            .flatMap { itemsByShelfID[$0] ?? [] }

        return Array(candidates.filter { seen.insert($0.id).inserted }.prefix(5))
    }

    public func items(for shelfID: String) -> [EntityThumbnail] {
        let items = itemsByShelfID[shelfID] ?? []
        return shelfID == "in-progress" ? Array(items.dropFirst()) : items
    }
}
