import Foundation

public enum VideoSubtitleSettingValue: Decodable, Equatable, Sendable {
    case bool(Bool)
    case number(Double)
    case string(String)
    case stringList([String])
    case unsupported

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([String].self) {
            self = .stringList(value)
        } else {
            self = .unsupported
        }
    }
}
