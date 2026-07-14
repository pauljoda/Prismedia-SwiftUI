import Foundation

public struct EntityGroup: Decodable, Hashable, Sendable {
    public let kind: EntityKind
    public let label: String
    public let entities: [EntityThumbnail]
    public let code: String?
}
