import Foundation

public struct EntityChildrenBatchGroup: Decodable, Hashable, Sendable {
    public let parentId: UUID
    public let items: [EntityThumbnail]
}
