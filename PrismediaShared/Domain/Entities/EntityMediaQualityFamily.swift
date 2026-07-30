import Foundation

/// Canonical media family used to select quality-comparison and upgrade behavior.
public struct EntityMediaQualityFamily: RawRepresentable, Codable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
