import Foundation

public struct EntityGridConfiguration: Hashable, Sendable {
    public let title: String
    public let query: EntityListQuery
    public let supportsSearch: Bool
    public let pageSize: Int
    public let minimumColumnWidth: CGFloat
    public let preferencesID: String
    public let defaultDisplayMode: EntityGridDisplayMode

    public init(
        title: String,
        query: EntityListQuery,
        supportsSearch: Bool = false,
        pageSize: Int = 48,
        minimumColumnWidth: CGFloat = 150,
        defaultDisplayMode: EntityGridDisplayMode = .grid,
        preferencesID: String? = nil
    ) {
        precondition(pageSize > 0, "An entity grid page size must be positive.")
        precondition(minimumColumnWidth > 0, "An entity grid column width must be positive.")

        self.title = title
        self.query = query
        self.supportsSearch = supportsSearch
        self.pageSize = pageSize
        self.minimumColumnWidth = minimumColumnWidth
        self.defaultDisplayMode = defaultDisplayMode
        self.preferencesID = preferencesID ?? Self.defaultPreferencesID(title: title, query: query)
    }

    private static func defaultPreferencesID(title: String, query: EntityListQuery) -> String {
        let kind = query.kind?.rawValue ?? query.kinds.map(\.rawValue).joined(separator: ",")
        let routeConstraints = [query.bookType, query.bookFormat]
            .compactMap { $0 }
            .joined(separator: ":")
        return [title.lowercased(), kind, routeConstraints]
            .filter { !$0.isEmpty }
            .joined(separator: ":")
    }
}
