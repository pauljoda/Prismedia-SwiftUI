import Foundation

/// Saved state of an exact external-library holding.
public struct EntityManagedTrackingStatus: RawRepresentable, Codable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
