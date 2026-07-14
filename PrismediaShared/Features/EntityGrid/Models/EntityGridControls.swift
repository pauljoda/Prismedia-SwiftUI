import Foundation

public struct EntityGridControls: Hashable, Sendable {
    public var sort: EntityGridSort?
    public var sortDescending: Bool
    public var randomSeed: Int
    public var filters: EntityGridFilters

    public init(baselineQuery: EntityListQuery) {
        sort = baselineQuery.sort.flatMap(EntityGridSort.init(rawValue:))
        sortDescending = baselineQuery.sortDescending
        randomSeed = Self.nextRandomSeed()
        filters = EntityGridFilters()
    }

    public static func nextRandomSeed() -> Int {
        Int.random(in: 1...2_000_000_000)
    }

    public func applying(to baseline: EntityListQuery) -> EntityListQuery {
        var query = baseline
        if let sort {
            query.sort = sort.rawValue
            query.sortDescending = sortDescending
            query.seed = sort == .random ? randomSeed : nil
        }
        if filters.favoriteOnly { query.favorite = true }
        if filters.organization != .any {
            query.organized = filters.organization == .organized
        }
        if filters.availability != .any || filters.acquisitionStatus != nil {
            query.hasFile = filters.availability == .onDisk ? true : nil
            query.wanted = filters.availability == .wanted ? true : nil
            query.acquisitionStatus = filters.acquisitionStatus
        }
        if let engagementStatus { query.status = engagementStatus }
        if let minimumRating { query.ratingMin = minimumRating }
        if let maximumRating = filters.maximumRating { query.ratingMax = maximumRating }
        if filters.rating == .unrated {
            query.unrated = true
            query.ratingMin = nil
            query.ratingMax = nil
        }
        if filters.taxonomy != .any {
            query.orphaned = filters.taxonomy == .orphaned
        }
        if !filters.bookTypes.isEmpty { query.bookType = filters.bookTypes.sorted().joined(separator: ",") }
        if !filters.bookFormats.isEmpty { query.bookFormat = filters.bookFormats.sorted().joined(separator: ",") }
        return query
    }

    private var engagementStatus: String? {
        switch filters.engagement {
        case .any: nil
        case .watched: "watched"
        case .unwatched: "unwatched"
        case .inProgress: "in-progress"
        }
    }

    private var minimumRating: Int? {
        guard case .atLeast(let value) = filters.rating else { return nil }
        return value
    }
}
