import Foundation

/// Backend-owned engagement vocabulary used by grid filtering and completion presentation.
public struct EntityEngagementMode: RawRepresentable, Codable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
