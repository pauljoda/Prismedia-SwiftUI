import Foundation

public struct SearchHubResultSection: Identifiable, Hashable, Sendable {
    public let kind: EntityKind
    public let items: [EntityThumbnail]

    public var id: String { kind.rawValue }
    public var title: String { SearchHubCatalog.sectionTitle(for: kind) }
}
