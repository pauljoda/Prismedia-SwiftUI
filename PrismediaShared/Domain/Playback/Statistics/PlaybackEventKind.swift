import Foundation

public struct PlaybackEventKind: RawRepresentable, Codable, Hashable, Sendable {
    public static let completed = Self(rawValue: "completed")
    public static let skipped = Self(rawValue: "skipped")
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
