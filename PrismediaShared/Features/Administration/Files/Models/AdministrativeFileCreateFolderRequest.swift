import Foundation

struct AdministrativeFileCreateFolderRequest: Encodable, Sendable {
    let rootID: UUID
    let parentPath: String
    let name: String

    enum CodingKeys: String, CodingKey {
        case rootID = "rootId"
        case parentPath, name
    }
}
