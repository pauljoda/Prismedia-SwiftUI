import Foundation

public struct AdministrativeDatabaseBackup: Decodable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public let fileName: String
    public let backupPath: String
    public let status: String
    public let isManual: Bool
    public let sizeBytes: Int64?
    public let createdAt: Date
    public let completedAt: Date?
    public let expiresAt: Date?
    public let error: String?

    public init(
        id: UUID,
        fileName: String,
        backupPath: String,
        status: String,
        isManual: Bool,
        sizeBytes: Int64?,
        createdAt: Date,
        completedAt: Date?,
        expiresAt: Date?,
        error: String?
    ) {
        self.id = id
        self.fileName = fileName
        self.backupPath = backupPath
        self.status = status
        self.isManual = isManual
        self.sizeBytes = sizeBytes
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.expiresAt = expiresAt
        self.error = error
    }
}
