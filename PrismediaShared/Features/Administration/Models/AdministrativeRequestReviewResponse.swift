import Foundation

public struct AdministrativeRequestReviewResponse: Decodable, Hashable, Sendable {
    public let pluginID: String
    public let externalIdentity: AdministrativeExternalIdentity
    public let entityKind: EntityKind
    public let kind: String
    public let proposal: AdministrativeEntityMetadataProposal
    public let revision: String
    public let targets: [AdministrativeRequestReviewTarget]

    enum CodingKeys: String, CodingKey {
        case pluginID = "pluginId"
        case externalIdentity, entityKind, kind, proposal, revision, targets
    }
}
