import Foundation

/// Book-only metadata used to choose reader behavior and presentation.
public struct EntityBookMetadataCapability: Decodable, Hashable, Sendable {
    public let bookType: String
    public let format: BookFormat
}
