import Foundation

/// Client-rendered surface surrounding untouched Entity artwork.
public struct EntityArtworkSurface: RawRepresentable, Codable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
