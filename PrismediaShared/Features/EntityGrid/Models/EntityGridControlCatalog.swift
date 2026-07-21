import Foundation

public struct EntityGridControlCatalog: Hashable, Sendable {
    public let query: EntityListQuery

    public init(query: EntityListQuery) {
        self.query = query
    }

    public var sortOptions: [EntityGridSort] {
        var options: [EntityGridSort] = [.title, .added, .lastAccessed, .rating, .random]
        if supportsTaxonomyFilters { options.append(.references) }
        return options
    }

    public var supportsTaxonomyFilters: Bool {
        query.kind == .tag || query.kind == .person || query.kind == .studio
    }

    public var supportsBookFilters: Bool {
        query.kind == .book && query.bookType == nil && query.bookFormat == nil
    }

    public var supportsEngagementFilters: Bool {
        guard let kind = query.kind else { return true }
        return [.video, .videoSeries, .videoSeason, .audioLibrary, .audioTrack, .book, .bookVolume, .bookChapter]
            .contains(kind)
    }

    public var usesReadingLabels: Bool {
        guard let kind = query.kind else { return false }
        return [.book, .bookVolume, .bookChapter].contains(kind)
    }
}
