import Foundation

public struct EntityCreditMetadata: Decodable, Hashable, Sendable {
    public let personID: UUID
    public let role: String?
    public let character: String?
    public let roles: [String]
    public let characters: [String]

    private enum CodingKeys: String, CodingKey {
        case personID = "personId"
        case role
        case character
        case roles
        case characters
    }
}
