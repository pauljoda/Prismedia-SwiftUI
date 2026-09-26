import Foundation

/// One accepted source statement for an imported file on this Entity.
public struct EntityAcquisitionAttribution: Decodable, Hashable, Sendable {
    public let operationID: UUID
    public let acceptedAt: Date
    public let attribution: EntityCatalogAttribution

    private enum CodingKeys: String, CodingKey {
        case operationID = "operationId"
        case acceptedAt
        case attribution
    }
}
