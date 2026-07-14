import Foundation

struct CollectionRemoveItemsRequest: Encodable {
    let itemIDs: [UUID]

    private enum CodingKeys: String, CodingKey {
        case itemIDs = "itemIds"
    }
}
