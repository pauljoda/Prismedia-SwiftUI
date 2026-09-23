import Foundation

/// Saved fulfillment phase of an externally managed request.
public struct EntityManagedRequestPhase: RawRepresentable, Codable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
