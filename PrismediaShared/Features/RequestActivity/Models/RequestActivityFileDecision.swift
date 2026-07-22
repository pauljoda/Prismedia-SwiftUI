import Foundation

public struct RequestActivityFileDecision: Codable, Equatable, Hashable, Sendable {
    public enum Value: String, Sendable {
        case placeNew = "place-new"
        case replaceUpgrade = "replace-upgrade"
        case adoptExisting = "adopt-existing"
        case skipExisting = "skip-existing"
        case skipNotUpgrade = "skip-not-upgrade"
        case holdFormatChange = "hold-format-change"
        case holdStructuralConflict = "hold-structural-conflict"
        case unsupported, ambiguous
    }

    public let rawValue: String
    public var value: Value? { Value(rawValue: rawValue) }
    public init(value: Value) { rawValue = value.rawValue }
    public init(from decoder: any Decoder) throws { rawValue = try decoder.singleValueContainer().decode(String.self) }
    public func encode(to encoder: any Encoder) throws { var container = encoder.singleValueContainer(); try container.encode(rawValue) }
}
