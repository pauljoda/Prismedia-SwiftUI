import Foundation

public struct WantedRemovalFailure: Decodable, Equatable, Sendable {
    public let entityID: UUID
    public let message: String

    public init(entityID: UUID, message: String) {
        self.entityID = entityID
        self.message = message
    }

    private enum CodingKeys: String, CodingKey {
        case entityID = "entityId"
        case message
    }
}
