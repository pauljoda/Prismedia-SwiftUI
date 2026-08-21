import Foundation

/// Forward-compatible page-reading direction from the page-sequence capability.
public struct PageReadingDirection: RawRepresentable, Codable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
