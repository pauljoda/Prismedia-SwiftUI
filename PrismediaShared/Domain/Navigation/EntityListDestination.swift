import Foundation

/// Server-backed entity content owned by one shell destination.
public struct EntityListDestination: Hashable, Sendable {
    public let query: EntityListQuery
    public let supportsSearch: Bool

    public init(query: EntityListQuery, supportsSearch: Bool = true) {
        self.query = query
        self.supportsSearch = supportsSearch
    }
}
