import Foundation

/// Default artwork scaling mode owned by an Entity-kind definition.
public struct EntityArtworkFit: RawRepresentable, Codable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
