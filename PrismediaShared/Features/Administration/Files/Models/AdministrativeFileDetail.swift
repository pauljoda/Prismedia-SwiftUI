import Foundation

public struct AdministrativeFileDetail: Decodable, Hashable, Sendable {
    public let entry: AdministrativeFileEntry
    public let absolutePath: String
    public let createdAt: Date?
    public let linkedEntities: [AdministrativeFileLinkedEntity]
    public let canPreview: Bool
    public let directoryFileCount: Int64?
    public let directoryTotalSizeBytes: Int64?
}
