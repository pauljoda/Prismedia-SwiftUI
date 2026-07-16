import Foundation

struct AdministrativeDatabaseRestoreRequest: Encodable, Sendable {
    let backupID: UUID
    let confirmationText: String

    private enum CodingKeys: String, CodingKey {
        case confirmationText
        case backupID = "backupId"
    }
}
