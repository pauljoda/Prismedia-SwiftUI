import Foundation

public struct AdministrativeDatabaseRestoreScheduled: Decodable, Hashable, Sendable {
    public let backupID: UUID
    public let requestedAt: Date
    public let restartScheduled: Bool

    private enum CodingKeys: String, CodingKey {
        case requestedAt, restartScheduled
        case backupID = "backupId"
    }
}
