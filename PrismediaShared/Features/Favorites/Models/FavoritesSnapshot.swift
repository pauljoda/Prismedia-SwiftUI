public struct FavoritesSnapshot: Equatable, Sendable {
    public var sections: [FavoritesSection]
    public var state: FavoritesState

    public init(
        sections: [FavoritesSection] = [],
        state: FavoritesState = .idle
    ) {
        self.sections = sections
        self.state = state
    }
}
