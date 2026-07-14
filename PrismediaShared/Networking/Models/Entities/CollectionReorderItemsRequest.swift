import Foundation

struct CollectionReorderItemsRequest: Encodable {
    let itemIDs: [UUID]

    private enum CodingKeys: String, CodingKey {
        case itemIDs = "itemIds"
    }
}
