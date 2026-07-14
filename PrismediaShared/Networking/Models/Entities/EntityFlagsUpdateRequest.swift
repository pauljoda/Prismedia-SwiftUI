import Foundation

struct EntityFlagsUpdateRequest: Encodable {
    let isFavorite: Bool?
    let isNsfw: Bool?
    let isOrganized: Bool?

    private enum CodingKeys: String, CodingKey {
        case isFavorite
        case isNsfw
        case isOrganized
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeNullable(isFavorite, forKey: .isFavorite)
        try container.encodeNullable(isNsfw, forKey: .isNsfw)
        try container.encodeNullable(isOrganized, forKey: .isOrganized)
    }
}

extension KeyedEncodingContainer {
    fileprivate mutating func encodeNullable<Value: Encodable>(_ value: Value?, forKey key: Key) throws {
        if let value {
            try encode(value, forKey: key)
        } else {
            try encodeNil(forKey: key)
        }
    }
}
