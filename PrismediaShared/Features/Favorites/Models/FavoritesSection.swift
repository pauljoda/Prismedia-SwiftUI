import Foundation

public struct FavoritesSection: Identifiable, Equatable, Sendable {
    public let definition: FavoritesSectionDefinition
    public let items: [EntityThumbnail]

    public var id: String { definition.id }
}
