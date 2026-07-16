import Foundation

struct CollectionItemResponse: Decodable, Sendable {
    let id: UUID?
    let entityID: UUID?
    let entity: EntityThumbnail

    private enum CodingKeys: String, CodingKey {
        case id
        case entityID = "entityId"
        case entity
    }
}
