import Foundation

struct CollectionItemsResponse: Decodable, Sendable {
    let items: [CollectionItemResponse]

    var entities: [EntityThumbnail] {
        items.map(\.entity)
    }
}
