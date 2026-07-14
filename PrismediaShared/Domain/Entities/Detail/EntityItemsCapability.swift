import Foundation

public struct EntityItemsCapability<Item: Decodable & Hashable & Sendable>: Decodable, Hashable, Sendable {
    public let items: [Item]
}
