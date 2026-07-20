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

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        proposalID = try container.decode(String.self, forKey: .proposalID)
        provider = try container.decode(String.self, forKey: .provider)
        targetKind = try container.decode(String.self, forKey: .targetKind)
        confidence = try container.decodeIfPresent(Decimal.self, forKey: .confidence)
        matchReason = try container.decodeIfPresent(String.self, forKey: .matchReason)
        patch = try container.decode(AdministrativeEntityMetadataPatch.self, forKey: .patch)
        // Prismedia serializes empty proposal collections as explicit nulls;
        // treat null or missing as empty so deep trees keep decoding.
        images = try container.decodeIfPresent([AdministrativeImageCandidate].self, forKey: .images) ?? []
        children =
            try container.decodeIfPresent([AdministrativeEntityMetadataProposal].self, forKey: .children) ?? []
        candidates =
            try container.decodeIfPresent([AdministrativeEntitySearchCandidate].self, forKey: .candidates) ?? []
        targetEntityID = try container.decodeIfPresent(UUID.self, forKey: .targetEntityID)
        relationships =
            try container.decodeIfPresent([AdministrativeEntityMetadataProposal].self, forKey: .relationships) ?? []
    }

    public init(
        proposalID: String,
        provider: String,
        targetKind: String,
        confidence: Decimal?,
        matchReason: String?,
        patch: AdministrativeEntityMetadataPatch,
        images: [AdministrativeImageCandidate],
        children: [AdministrativeEntityMetadataProposal],
        candidates: [AdministrativeEntitySearchCandidate],
        targetEntityID: UUID?,
        relationships: [AdministrativeEntityMetadataProposal]
    ) {
        self.proposalID = proposalID
        self.provider = provider
        self.targetKind = targetKind
        self.confidence = confidence
        self.matchReason = matchReason
        self.patch = patch
        self.images = images
        self.children = children
        self.candidates = candidates
        self.targetEntityID = targetEntityID
        self.relationships = relationships
    }
}
