import Foundation

public struct AdministrativeRequestCommitResponse: Decodable, Hashable, Sendable {
    public let containerEntityID: UUID?
    public let items: [AdministrativeRequestCommitItem]

    enum CodingKeys: String, CodingKey {
        case containerEntityID = "containerEntityId"
        case items
    }
}
