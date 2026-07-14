import Foundation

enum RequestActivityDecoding {
    static func integer<Key: CodingKey>(
        from container: KeyedDecodingContainer<Key>,
        forKey key: Key
    ) throws -> Int {
        if let value = try? container.decode(Int.self, forKey: key) { return value }
        let value = try container.decode(String.self, forKey: key)
        guard let result = Int(value) else {
            throw DecodingError.dataCorruptedError(forKey: key, in: container, debugDescription: "Expected an integer.")
        }
        return result
    }

    static func optionalInteger<Key: CodingKey>(
        from container: KeyedDecodingContainer<Key>,
        forKey key: Key
    ) throws -> Int? {
        guard container.contains(key), try !container.decodeNil(forKey: key) else { return nil }
        return try integer(from: container, forKey: key)
    }

    static func integer64<Key: CodingKey>(
        from container: KeyedDecodingContainer<Key>,
        forKey key: Key
    ) throws -> Int64 {
        if let value = try? container.decode(Int64.self, forKey: key) { return value }
        let value = try container.decode(String.self, forKey: key)
        guard let result = Int64(value) else {
            throw DecodingError.dataCorruptedError(
                forKey: key, in: container, debugDescription: "Expected a 64-bit integer.")
        }
        return result
    }

    static func optionalInteger64<Key: CodingKey>(
        from container: KeyedDecodingContainer<Key>,
        forKey key: Key
    ) throws -> Int64? {
        guard container.contains(key), try !container.decodeNil(forKey: key) else { return nil }
        return try integer64(from: container, forKey: key)
    }

    static func double<Key: CodingKey>(
        from container: KeyedDecodingContainer<Key>,
        forKey key: Key
    ) throws -> Double {
        if let value = try? container.decode(Double.self, forKey: key) { return value }
        let value = try container.decode(String.self, forKey: key)
        guard let result = Double(value) else {
            throw DecodingError.dataCorruptedError(forKey: key, in: container, debugDescription: "Expected a number.")
        }
        return result
    }

    static func optionalDouble<Key: CodingKey>(
        from container: KeyedDecodingContainer<Key>,
        forKey key: Key
    ) throws -> Double? {
        guard container.contains(key), try !container.decodeNil(forKey: key) else { return nil }
        return try double(from: container, forKey: key)
    }
}
