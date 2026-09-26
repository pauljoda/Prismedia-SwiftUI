import Foundation

/// Durable external request state, including its current waiting or error explanation.
public struct EntityManagedRequestReference: Decodable, Hashable, Sendable {
    public let requestID: UUID
    public let phase: EntityManagedRequestPhase
    public let updatedAt: Date
    public let problem: String?

    private enum CodingKeys: String, CodingKey {
        case requestID = "requestId"
        case phase
        case updatedAt
        case problem
    }
}
