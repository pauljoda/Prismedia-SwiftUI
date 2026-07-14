import Foundation

public struct AdministrativeIdentifyApplyProgress: Decodable, Hashable, Sendable {
    public let id: UUID
    public let entityID: UUID
    public let state: String
    public let currentIndex: Int
    public let total: Int
    public let currentKind: EntityKind?
    public let currentTitle: String?
    public let currentPath: [String]
    public let error: String?
    public let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case entityID = "entityId"
        case state, currentIndex, total, currentKind, currentTitle, currentPath, error, updatedAt
    }
}
