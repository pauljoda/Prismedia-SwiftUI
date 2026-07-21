public protocol FavoritesLoading: Sendable {
    func load(_ query: EntityListQuery, limit: Int) async throws -> EntityListResponse
}
