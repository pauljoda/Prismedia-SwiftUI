import Foundation

struct CollectionRemoveItemsRequest: Encodable, Sendable {
    let itemIds: [UUID]
}
