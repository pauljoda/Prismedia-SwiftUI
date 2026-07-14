import Foundation

public struct EntityLifetimeCapability: Decodable, Hashable, Sendable {
    public let start: EntityDate?
    public let end: EntityDate?
    public let label: String?
}
