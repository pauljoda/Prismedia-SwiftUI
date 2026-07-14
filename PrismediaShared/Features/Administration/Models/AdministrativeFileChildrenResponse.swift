import Foundation

public struct AdministrativeFileChildrenResponse: Decodable, Sendable {
    public let rootID: UUID
    public let path: String
    public let entries: [AdministrativeFileEntry]

    enum CodingKeys: String, CodingKey {
        case rootID = "rootId"
        case path, entries
    }
}
