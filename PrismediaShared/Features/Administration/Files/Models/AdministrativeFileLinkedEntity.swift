import Foundation

public struct AdministrativeFileLinkedEntity: Decodable, Identifiable, Hashable, Sendable {
    public let entityID: UUID
    public let kind: String
    public let title: String
    public let coverURL: String?
    public var id: UUID { entityID }

    enum CodingKeys: String, CodingKey {
        case entityID = "entityId"
        case kind, title
        case coverURL = "coverUrl"
    }
}
