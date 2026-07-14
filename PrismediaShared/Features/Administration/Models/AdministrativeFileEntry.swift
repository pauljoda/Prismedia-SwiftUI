import Foundation

public struct AdministrativeFileEntry: Codable, Identifiable, Hashable, Sendable {
    public var id: String { "\(rootID.uuidString):\(path)" }
    public let rootID: UUID
    public let path: String
    public let name: String
    public let kind: String
    public let sizeBytes: Int64?
    public let mimeType: String?
    public let modifiedAt: Date?
    public let excluded: Bool

    enum CodingKeys: String, CodingKey {
        case rootID = "rootId"
        case path, name, kind, sizeBytes, mimeType, modifiedAt, excluded
    }

    public var isDirectory: Bool { kind.caseInsensitiveCompare("directory") == .orderedSame }
}
