import Foundation

public struct AdministrativeRequestCommitItem: Decodable, Hashable, Sendable {
    public let externalID: String
    public let title: String
    public let outcome: String
    public let entityID: UUID?
    public let acquisitionID: UUID?

    enum CodingKeys: String, CodingKey {
        case externalID = "externalId"
        case title, outcome
        case entityID = "entityId"
        case acquisitionID = "acquisitionId"
    }
}
