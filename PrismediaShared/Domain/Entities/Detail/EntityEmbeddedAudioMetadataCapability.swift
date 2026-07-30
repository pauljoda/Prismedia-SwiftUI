import Foundation

/// Embedded track metadata that supplements linked artist and album entities.
public struct EntityEmbeddedAudioMetadataCapability: Decodable, Hashable, Sendable {
    public let artist: String?
    public let album: String?
}
