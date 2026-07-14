import Foundation

struct AdministrativeFileRescanRequest: Encodable, Sendable {
    let rootID: UUID
    let path: String?

    enum CodingKeys: String, CodingKey {
        case rootID = "rootId"
        case path
    }
}
