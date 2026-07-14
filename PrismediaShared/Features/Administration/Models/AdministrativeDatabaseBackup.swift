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
}
