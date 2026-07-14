import Foundation

public struct EntityThumbnailHoverImage: Decodable, Hashable, Sendable {
    public let entityID: UUID?
    public let title: String
    public let path: String

    public init(entityID: UUID?, title: String, path: String) {
        self.entityID = entityID
        self.title = title
        self.path = path
    }

    private enum CodingKeys: String, CodingKey {
        case entityID = "entityId"
        case title
        case path
    }
}
