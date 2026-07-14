import Foundation

#if os(iOS) || os(macOS)
    struct PrismediaIdentifyEntityBrowser: IdentifyEntityBrowsing {
        let client: PrismediaAPIClient

        func entities(kind: EntityKind, organized: Bool?, search: String?) async throws -> [EntityThumbnail] {
            try await client.listAllEntities(
                EntityListQuery(kind: kind, sort: "added", organized: organized),
                search: search
            )
        }
    }
#endif
