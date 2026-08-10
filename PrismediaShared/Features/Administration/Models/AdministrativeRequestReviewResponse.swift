import Foundation

public struct AdministrativeRequestReviewResponse: Codable, Hashable, Sendable {
    public let pluginID: String
    public let externalIdentity: AdministrativeExternalIdentity
    public let entityKind: EntityKind
    public let kind: String
    public let proposal: AdministrativeEntityMetadataProposal
    public let revision: String
    public let targets: [AdministrativeRequestReviewTarget]
    public let enrichment: AdministrativeRequestReviewEnrichment?

    public init(
        pluginID: String,
        externalIdentity: AdministrativeExternalIdentity,
        entityKind: EntityKind,
        kind: String,
        proposal: AdministrativeEntityMetadataProposal,
        revision: String,
        targets: [AdministrativeRequestReviewTarget],
        enrichment: AdministrativeRequestReviewEnrichment? = nil
    ) {
        self.pluginID = pluginID
        self.externalIdentity = externalIdentity
        self.entityKind = entityKind
        self.kind = kind
        self.proposal = proposal
        self.revision = revision
        self.targets = targets
        self.enrichment = enrichment
    }

    enum CodingKeys: String, CodingKey {
        case pluginID = "pluginId"
        case externalIdentity, entityKind, kind, proposal, revision, targets, enrichment
    }
}
