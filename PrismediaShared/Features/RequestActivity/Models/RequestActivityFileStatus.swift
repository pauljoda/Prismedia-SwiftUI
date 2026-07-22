import Foundation

public struct RequestActivityFileStatus: Codable, Equatable, Hashable, Sendable {
    public enum Value: String, Sendable {
        case downloaded
        case pendingImport = "pending-import"
        case importing, imported, skipped, failed
    }

    public let rawValue: String
    public var value: Value? { Value(rawValue: rawValue) }

    public init(value: Value) { rawValue = value.rawValue }
    public init(from decoder: any Decoder) throws { rawValue = try decoder.singleValueContainer().decode(String.self) }
    public func encode(to encoder: any Encoder) throws { var container = encoder.singleValueContainer(); try container.encode(rawValue) }
}
