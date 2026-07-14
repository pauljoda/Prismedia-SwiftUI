import Foundation

public struct BookFormat: RawRepresentable, Codable, Hashable, Sendable {
    public static let imageArchive = Self(rawValue: "image-archive")
    public static let epub = Self(rawValue: "epub")
    public static let pdf = Self(rawValue: "pdf")
    public static let audio = Self(rawValue: "audio")

    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
