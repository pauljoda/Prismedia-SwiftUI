import Foundation

public struct EntityGridMutationFailure: Equatable, Sendable {
    public let entityID: UUID
    public let title: String
    public let message: String

    public init(entityID: UUID, title: String, message: String) {
        self.entityID = entityID
        self.title = title
        self.message = message
    }
}
