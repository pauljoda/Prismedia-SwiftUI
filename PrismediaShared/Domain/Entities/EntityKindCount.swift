import Foundation

public struct EntityKindCount: Decodable, Hashable, Sendable {
    public let kind: EntityKind
    public let count: Int
}
