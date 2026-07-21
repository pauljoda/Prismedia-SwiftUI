import Foundation

public struct EntityGridTopContentContext: Equatable, Sendable {
    public let query: EntityListQuery
    public let search: String?
    public let visibleItemCount: Int

    public init(
        query: EntityListQuery,
        search: String?,
        visibleItemCount: Int
    ) {
        self.query = query
        self.search = search
        self.visibleItemCount = visibleItemCount
    }
}
