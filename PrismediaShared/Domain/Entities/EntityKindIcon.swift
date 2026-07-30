import Foundation

/// Platform-neutral icon code owned by the backend Entity-kind definition.
public struct EntityKindIcon: RawRepresentable, Codable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
