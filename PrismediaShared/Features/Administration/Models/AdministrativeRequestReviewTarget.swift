import Foundation

public struct AdministrativeRequestReviewTarget: Decodable, Hashable, Sendable {
    public let proposalID: String
    public let kind: String
    public let entityKind: EntityKind
    public let externalIdentity: AdministrativeExternalIdentity
    public let requestable: Bool
    public let position: Int?
    public let year: Int?
    public let monitored: Bool?

    enum CodingKeys: String, CodingKey {
        case proposalID = "proposalId"
        case kind, entityKind, externalIdentity, requestable, position, year, monitored
    }
}
