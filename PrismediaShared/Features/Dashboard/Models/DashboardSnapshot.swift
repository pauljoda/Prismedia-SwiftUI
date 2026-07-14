import Foundation

public struct DashboardSnapshot: Equatable, Sendable {
    public var featuredItems: [EntityThumbnail]
    public var continueItems: [EntityThumbnail]
    public var recentItems: [EntityThumbnail]
    public var sections: [DashboardSection]
    public var state: DashboardState

    public init(
        hero: EntityThumbnail? = nil,
        featuredItems: [EntityThumbnail] = [],
        continueItems: [EntityThumbnail] = [],
        recentItems: [EntityThumbnail] = [],
        sections: [DashboardSection] = [],
        state: DashboardState = .idle
    ) {
        self.featuredItems = featuredItems.isEmpty ? hero.map { [$0] } ?? [] : featuredItems
        self.continueItems = continueItems
        self.recentItems = recentItems
        self.sections = sections
        self.state = state
    }

    public var hero: EntityThumbnail? {
        featuredItems.first
    }

    var hasContent: Bool {
        !featuredItems.isEmpty || !continueItems.isEmpty || !recentItems.isEmpty
            || sections.contains { !$0.items.isEmpty }
    }
}
