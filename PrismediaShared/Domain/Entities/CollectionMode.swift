import Foundation

/// How a Collection gathers its members: hand-picked, rule-driven, or both. Unknown future mode codes are
/// preserved rather than rejected.
public struct CollectionMode: RawRepresentable, Codable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
