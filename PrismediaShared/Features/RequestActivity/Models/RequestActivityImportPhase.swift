import Foundation

public struct RequestActivityImportPhase: Codable, Equatable, Hashable, Sendable {
    public enum Value: String, Sendable {
        case downloading, downloaded, importing, imported
    }

    public let rawValue: String
    public var value: Value? { Value(rawValue: rawValue) }

    public init(value: Value) { rawValue = value.rawValue }
    public init(from decoder: any Decoder) throws { rawValue = try decoder.singleValueContainer().decode(String.self) }
    public func encode(to encoder: any Encoder) throws { var container = encoder.singleValueContainer(); try container.encode(rawValue) }
}
