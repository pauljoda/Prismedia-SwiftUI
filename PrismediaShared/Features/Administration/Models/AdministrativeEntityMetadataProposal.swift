import Foundation

public struct AdministrativeEntityMetadataProposal: Codable, Hashable, Sendable {
    public let proposalID: String
    public let provider: String
    public let targetKind: String
    public let confidence: Decimal?
    public let matchReason: String?
    public let patch: AdministrativeEntityMetadataPatch
    public let images: [AdministrativeImageCandidate]
    public let children: [AdministrativeEntityMetadataProposal]
    public let candidates: [AdministrativeEntitySearchCandidate]
    public let targetEntityID: UUID?
    public let relationships: [AdministrativeEntityMetadataProposal]

    enum CodingKeys: String, CodingKey {
        case proposalID = "proposalId"
        case provider, targetKind, confidence, matchReason, patch, images, children, candidates
        case targetEntityID = "targetEntityId"
        case relationships
    }
}
