import Foundation

#if os(iOS) || os(macOS)
    struct PrismediaIdentifyEntityBrowser: IdentifyEntityBrowsing {
        let client: PrismediaAPIClient

        public func entities(
            kind: EntityKind,
            organized: Bool?,
            search: String?
        ) async throws -> [EntityThumbnail] {
            try await client.listAllEntities(
                EntityListQuery(kind: kind, sort: "added", organized: organized),
                search: search
            )
        }

        public func detail(
            entityID: UUID,
            kind: EntityKind
        ) async throws -> EntityDetail {
            try await client.fetchEntity(id: entityID, kind: kind)
        }
    }
#endif
