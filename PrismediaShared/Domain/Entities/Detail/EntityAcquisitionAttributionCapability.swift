import Foundation

/// Retained attribution for completed imports; unreadable snapshots are reported separately.
public struct EntityAcquisitionAttributionCapability: Decodable, Hashable, Sendable {
    public let items: [EntityAcquisitionAttribution]
    public let unavailable: Bool
}
