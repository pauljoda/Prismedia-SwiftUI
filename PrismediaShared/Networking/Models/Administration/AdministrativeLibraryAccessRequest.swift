import Foundation

struct AdministrativeLibraryAccessRequest: Encodable, Sendable {
    let userIDs: [UUID]

    private enum CodingKeys: String, CodingKey {
        case userIDs = "userIds"
    }
}
