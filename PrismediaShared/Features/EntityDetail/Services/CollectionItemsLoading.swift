import Foundation

public protocol CollectionItemsLoading: Sendable {
    func loadCollectionItems(collectionID: UUID) async throws -> [EntityThumbnail]
}
