import Foundation

public enum AdministrativeJSONValue: Codable, Hashable, Sendable {
    case string(String)
    case stringList([String])
    case bool(Bool)
    case number(Double)
    case null
    case unsupported

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode([String].self) {
            self = .stringList(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else {
            self = .unsupported
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .stringList(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .number(let value):
            if value.rounded() == value { try container.encode(Int(value)) } else { try container.encode(value) }
        case .null: try container.encodeNil()
        case .unsupported:
            throw EncodingError.invalidValue(
                self, .init(codingPath: encoder.codingPath, debugDescription: "Unsupported setting value"))
        }
    }

    public var displayValue: String {
        switch self {
        case .string(let value): value
        case .stringList(let value): value.joined(separator: ", ")
        case .bool(let value): value ? "On" : "Off"
        case .number(let value): value.formatted()
        case .null: "Not set"
        case .unsupported: "Use the web app to edit"
        }
    }

    public var isEditableScalar: Bool {
        switch self {
        case .string, .stringList, .bool, .number: true
        case .null, .unsupported: false
        }
    }

    public var boolValue: Bool? {
        guard case .bool(let value) = self else { return nil }
        return value
    }

    public var stringValue: String? {
        guard case .string(let value) = self else { return nil }
        return value
    }

    public var numberValue: Double? {
        guard case .number(let value) = self else { return nil }
        return value
    }

    public var stringListValue: [String]? {
        guard case .stringList(let value) = self else { return nil }
        return value
    }
}
