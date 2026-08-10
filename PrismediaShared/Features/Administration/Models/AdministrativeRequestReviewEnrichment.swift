import Foundation

public struct AdministrativeRequestReviewEnrichment: Codable, Hashable, Sendable {
    public let reviewID: UUID
    public let running: Bool
    public let pendingProposalIDs: [String]
    public let error: String?
    public let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case reviewID = "reviewId"
        case running
        case pendingProposalIDs = "pendingProposalIds"
        case error, updatedAt
    }
}
