import Foundation

public struct EntityCapabilityKind: RawRepresentable, Codable, Hashable, Sendable {
    public static let classification = Self(rawValue: "classification")
    public static let dates = Self(rawValue: "dates")
    public static let description = Self(rawValue: "description")
    public static let fileManagement = Self(rawValue: "file-management")
    public static let files = Self(rawValue: "files")
    public static let fingerprints = Self(rawValue: "fingerprints")
    public static let flags = Self(rawValue: "flags")
    public static let images = Self(rawValue: "images")
    public static let lifetime = Self(rawValue: "lifetime")
    public static let links = Self(rawValue: "links")
    public static let markers = Self(rawValue: "markers")
    public static let playback = Self(rawValue: "playback")
    public static let position = Self(rawValue: "position")
    public static let progress = Self(rawValue: "progress")
    public static let providerIdentity = Self(rawValue: "provider-identity")
    public static let rating = Self(rawValue: "rating")
    public static let source = Self(rawValue: "source")
    public static let stats = Self(rawValue: "stats")
    public static let subtitles = Self(rawValue: "subtitles")
    public static let technical = Self(rawValue: "technical")

    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
