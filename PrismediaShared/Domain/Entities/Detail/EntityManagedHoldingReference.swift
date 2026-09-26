import Foundation

/// Exact saved external holding and its current tracking state.
public struct EntityManagedHoldingReference: Decodable, Hashable, Sendable {
    public let holdingID: UUID
    public let item: EntityManagedItemInput
    public let status: EntityManagedTrackingStatus

    private enum CodingKeys: String, CodingKey {
        case holdingID = "holdingId"
        case item
        case status
    }
}
