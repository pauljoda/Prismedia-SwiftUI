import Foundation

/// Explicit entity selected as the cover for an owning entity.
public struct EntityCoverSelectionCapability: Decodable, Hashable, Sendable {
    public let entityID: UUID?

    private enum CodingKeys: String, CodingKey {
        case entityID = "entityId"
    }
}
