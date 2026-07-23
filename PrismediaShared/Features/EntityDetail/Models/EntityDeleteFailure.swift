import Foundation

public struct EntityDeleteFailure: Decodable, Equatable, Sendable {
    public let id: UUID
    public let message: String

    public init(id: UUID, message: String) {
        self.id = id
        self.message = message
    }
}
