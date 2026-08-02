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
                EntityListQuery(kind: kind, sort: PrismediaContractCodes.EntityListSort.dateAdded, organized: organized),
                search: search
            )
        }

        public func detail(
            entityID: UUID,
            kind _: EntityKind
        ) async throws -> EntityDetail {
            try await client.fetchEntity(id: entityID)
        }
    }
#endif
