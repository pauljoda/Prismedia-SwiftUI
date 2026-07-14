import Foundation

extension KeyedDecodingContainer {
    func decodeFlexibleInt(forKey key: Key) throws -> Int {
        if let value = try decodeFlexibleIntIfPresent(forKey: key) { return value }
        throw DecodingError.valueNotFound(
            Int.self,
            .init(codingPath: codingPath + [key], debugDescription: "Expected an integer or integer string.")
        )
    }

    func decodeFlexibleDoubleIfPresent(forKey key: Key) throws -> Double? {
        if let value = try? decode(Double.self, forKey: key) { return value }
        if let value = try? decode(String.self, forKey: key) { return Double(value) }
        return nil
    }

    func decodeFlexibleDouble(forKey key: Key) throws -> Double {
        if let value = try decodeFlexibleDoubleIfPresent(forKey: key) { return value }
        throw DecodingError.valueNotFound(
            Double.self,
            .init(codingPath: codingPath + [key], debugDescription: "Expected a number or numeric string.")
        )
    }

    func decodeFlexibleString(forKey key: Key) throws -> String {
        if let value = try? decode(String.self, forKey: key) { return value }
        if let value = try? decode(Int.self, forKey: key) { return String(value) }
        if let value = try? decode(Double.self, forKey: key) { return String(value) }
        throw DecodingError.valueNotFound(
            String.self,
            .init(codingPath: codingPath + [key], debugDescription: "Expected a string or number.")
        )
    }
}

extension KeyedDecodingContainer {
    func decodeFlexibleIntIfPresent(forKey key: Key) throws -> Int? {
        if let intValue = try? decodeIfPresent(Int.self, forKey: key) {
            return intValue
        }

        if let stringValue = try? decodeIfPresent(String.self, forKey: key) {
            return Int(stringValue)
        }

        return nil
    }
}
