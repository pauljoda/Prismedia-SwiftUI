import Foundation

public enum SearchHubKindCatalog {
    public static let kinds: [EntityKind] = generatedEntityKindDefinitions.values
        .compactMap { definition in
            definition.search.map { (order: $0.order, kind: definition.kind) }
        }
        .sorted { $0.order < $1.order }
        .map(\.kind)

    public static var allKinds: Set<EntityKind> {
        Set(kinds)
    }

    public static func label(for kind: EntityKind) -> String {
        kind.groupLabel
    }

    public static func systemImage(for kind: EntityKind) -> String {
        kind.thumbnailFallbackSystemImage
    }
}
