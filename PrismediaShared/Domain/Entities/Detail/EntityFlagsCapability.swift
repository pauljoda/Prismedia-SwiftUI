import Foundation

public struct EntityFlagsCapability: Decodable, Hashable, Sendable {
    public let isFavorite: Bool?
    public let isNsfw: Bool?
    public let isOrganized: Bool?
    public let isWanted: Bool?
}
