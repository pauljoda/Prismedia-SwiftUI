import Foundation

public struct RequestActivityBlocklistEntry: Decodable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let reason: RequestActivityBlocklistReason
    public let title: String?
    public let indexerName: String?
    public let infoHash: String?
    public let acquisitionID: UUID?
    public let entityID: UUID?
    public let entityKind: EntityKind?
    public let entityTitle: String?
    public let message: String?
    public let createdAt: Date

    private enum CodingKeys: String, CodingKey {
        case id
        case reason
        case title
        case indexerName
        case infoHash
        case acquisitionID = "acquisitionId"
        case entityID = "entityId"
        case entityKind
        case entityTitle
        case message
        case createdAt
    }
}
