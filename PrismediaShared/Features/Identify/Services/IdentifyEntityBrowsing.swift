import Foundation

public protocol IdentifyEntityBrowsing: Sendable {
    func entities(kind: EntityKind, organized: Bool?, search: String?) async throws -> [EntityThumbnail]
}
