import Foundation

#if os(iOS) || os(macOS)
    protocol IdentifyEntityBrowsing: Sendable {
        func entities(kind: EntityKind, organized: Bool?, search: String?) async throws -> [EntityThumbnail]
    }
#endif
