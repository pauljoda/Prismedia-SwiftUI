import Foundation

public struct EntityCapabilityKind: RawRepresentable, Codable, Hashable, Sendable {
    public static let classification = Self(rawValue: "classification")
    public static let bookMetadata = Self(rawValue: "book-metadata")
    public static let collectionConfiguration = Self(rawValue: "collection-configuration")
    public static let coverSelection = Self(rawValue: "cover-selection")
    public static let credits = Self(rawValue: "credits")
    public static let dates = Self(rawValue: "dates")
    public static let description = Self(rawValue: "description")
    public static let embeddedAudioMetadata = Self(rawValue: "embedded-audio-metadata")
    public static let fileManagement = Self(rawValue: "file-management")
    public static let files = Self(rawValue: "files")
    public static let fingerprints = Self(rawValue: "fingerprints")
    public static let flags = Self(rawValue: "flags")
    public static let galleryMetadata = Self(rawValue: "gallery-metadata")
    public static let images = Self(rawValue: "images")
    public static let lifetime = Self(rawValue: "lifetime")
    public static let links = Self(rawValue: "links")
    public static let markers = Self(rawValue: "markers")
    public static let playback = Self(rawValue: "playback")
    public static let personProfile = Self(rawValue: "person-profile")
    public static let position = Self(rawValue: "position")
    public static let progress = Self(rawValue: "progress")
    public static let providerIdentity = Self(rawValue: "provider-identity")
    public static let rating = Self(rawValue: "rating")
    public static let source = Self(rawValue: "source")
    public static let seriesMetadata = Self(rawValue: "series-metadata")
    public static let stats = Self(rawValue: "stats")
    public static let subtitles = Self(rawValue: "subtitles")
    public static let tagPolicy = Self(rawValue: "tag-policy")
    public static let technical = Self(rawValue: "technical")

    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
