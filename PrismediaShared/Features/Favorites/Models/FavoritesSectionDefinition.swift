import Foundation

public struct FavoritesSectionDefinition: Identifiable, Hashable, Sendable {
    public let kind: EntityKind
    public let title: String
    public let systemImage: String
    public let colorRole: DashboardSectionColorRole
    public let destinationID: String
    public let query: EntityListQuery

    public var id: String { kind.rawValue }
}
