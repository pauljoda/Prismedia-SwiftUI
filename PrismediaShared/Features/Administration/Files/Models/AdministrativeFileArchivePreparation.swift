import Foundation

public struct AdministrativeFileArchivePreparation: Decodable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public let fileName: String
    public let ready: Bool
    public let progressPercent: Int
    public let processedFiles: Int
    public let totalFiles: Int
    public let error: String?
}
