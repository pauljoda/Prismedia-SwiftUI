import Foundation

public struct ReaderMode: RawRepresentable, Codable, Hashable, Sendable {
    public static let paged = Self(rawValue: "paged")
    public static let webtoon = Self(rawValue: "webtoon")
    public static let scrolled = Self(rawValue: "scrolled")

    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
