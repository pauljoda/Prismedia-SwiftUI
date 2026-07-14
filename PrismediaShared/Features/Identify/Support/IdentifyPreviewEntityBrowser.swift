import Foundation

#if DEBUG && (os(iOS) || os(macOS))
    struct IdentifyPreviewEntityBrowser: IdentifyEntityBrowsing {
        func entities(kind: EntityKind, organized: Bool?, search: String?) async throws -> [EntityThumbnail] {
            [
                EntityThumbnail(
                    id: UUID(uuidString: "a1000000-0000-0000-0000-000000000001")!,
                    kind: kind,
                    title: "Unmatched Example",
                    isOrganized: false
                ),
                EntityThumbnail(
                    id: UUID(uuidString: "a1000000-0000-0000-0000-000000000002")!,
                    kind: kind,
                    title: "Another Library Item",
                    isOrganized: organized ?? true
                ),
            ].filter { item in
                guard let search, !search.isEmpty else { return true }
                return item.title.localizedCaseInsensitiveContains(search)
            }
        }
    }
#endif
