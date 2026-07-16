import Foundation

public struct AdministrativeDatabaseBackupList: Decodable, Hashable, Sendable {
    public let backups: [AdministrativeDatabaseBackup]
    public let nextAutomaticBackupAt: Date?
    public let backupDirectory: String
    public let automaticRetentionDays: Int
    public let restoreConfirmationText: String

    public init(
        backups: [AdministrativeDatabaseBackup],
        nextAutomaticBackupAt: Date?,
        backupDirectory: String,
        automaticRetentionDays: Int,
        restoreConfirmationText: String
    ) {
        self.backups = backups
        self.nextAutomaticBackupAt = nextAutomaticBackupAt
        self.backupDirectory = backupDirectory
        self.automaticRetentionDays = automaticRetentionDays
        self.restoreConfirmationText = restoreConfirmationText
    }
}
