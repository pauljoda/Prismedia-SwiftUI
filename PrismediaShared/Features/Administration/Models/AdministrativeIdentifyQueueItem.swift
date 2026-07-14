import Foundation

public struct AdministrativeIdentifyQueueItem: Decodable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public let entityID: UUID
    public let entityKind: EntityKind
    public let title: String
    public let isNsfw: Bool
    public let state: String
    public let provider: String?
    public let action: String
    public let query: AdministrativeIdentifyQuery?
    public let candidates: [AdministrativeEntitySearchCandidate]
    public let proposal: AdministrativeEntityMetadataProposal?
    public let error: String?
    public let cascadeRunning: Bool
    public let createdAt: Date
    public let updatedAt: Date
    public let completedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case entityID = "entityId"
        case entityKind, title, isNsfw, state, provider, action, query, candidates, proposal, error, cascadeRunning
        case createdAt, updatedAt, completedAt
    }
}
