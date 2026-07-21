import Foundation

struct AdministrativeFileRenameRequest: Encodable, Sendable {
    let rootID: UUID
    let path: String
    let name: String

    enum CodingKeys: String, CodingKey {
        case rootID = "rootId"
        case path, name
    }
}
