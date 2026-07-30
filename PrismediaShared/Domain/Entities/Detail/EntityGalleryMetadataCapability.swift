import Foundation

/// Gallery-only organization metadata.
public struct EntityGalleryMetadataCapability: Decodable, Hashable, Sendable {
    public let galleryType: String
}
