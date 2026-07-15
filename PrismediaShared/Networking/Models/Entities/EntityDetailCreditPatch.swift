import Foundation

public struct EntityDetailCreditPatch: Encodable, Hashable, Sendable {
    public let name: String
    public let role: String
    public let character: String?
    public let sortOrder: Int?

    public init(
        name: String,
        role: String,
        character: String?,
        sortOrder: Int?
    ) {
        self.name = name
        self.role = role
        self.character = character
        self.sortOrder = sortOrder
    }
}
