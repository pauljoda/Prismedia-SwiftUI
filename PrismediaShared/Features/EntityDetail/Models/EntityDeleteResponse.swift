import Foundation

public struct EntityDeleteResponse: Decodable, Equatable, Sendable {
    public let deleted: Int
    public let filesDeleted: Int
    public let failures: [EntityDeleteFailure]
    public let reverted: Int

    public init(
        deleted: Int,
        filesDeleted: Int,
        failures: [EntityDeleteFailure] = [],
        reverted: Int = 0
    ) {
        self.deleted = deleted
        self.filesDeleted = filesDeleted
        self.failures = failures
        self.reverted = reverted
    }

    private enum CodingKeys: String, CodingKey {
        case deleted
        case filesDeleted
        case failures
        case reverted
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        deleted = try container.decodeFlexibleInt(forKey: .deleted)
        filesDeleted = try container.decodeFlexibleInt(forKey: .filesDeleted)
        failures = try container.decodeIfPresent([EntityDeleteFailure].self, forKey: .failures) ?? []
        reverted = try container.decodeFlexibleIntIfPresent(forKey: .reverted) ?? 0
    }
}
