import Foundation

public struct DashboardSection: Identifiable, Equatable, Sendable {
    public let definition: DashboardSectionDefinition
    public let items: [EntityThumbnail]

    public var id: String { definition.id }
    public var kind: EntityKind { definition.kind }
    public var title: String { definition.title }
    public var systemImage: String { definition.systemImage }
}
