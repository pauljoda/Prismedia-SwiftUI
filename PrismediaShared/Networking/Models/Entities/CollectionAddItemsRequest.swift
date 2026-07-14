import Foundation

struct CollectionAddItemsRequest: Encodable {
    let items: [CollectionEntityReference]
}
