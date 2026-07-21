import Foundation

struct AdministrativeFileMoveRequest: Encodable, Sendable {
    let sourceRootID: UUID
    let sourcePath: String
    let targetRootID: UUID
    let targetPath: String

    enum CodingKeys: String, CodingKey {
        case sourceRootID = "sourceRootId"
        case sourcePath
        case targetRootID = "targetRootId"
        case targetPath
    }
}
