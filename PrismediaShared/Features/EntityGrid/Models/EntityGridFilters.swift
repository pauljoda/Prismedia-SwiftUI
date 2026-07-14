public struct EntityGridFilters: Hashable, Sendable {
    public var favoriteOnly = false
    public var organization: EntityGridOrganizationFilter = .any
    public var availability: EntityGridAvailabilityFilter = .any
    public var acquisitionStatus: AcquisitionStatus?
    public var engagement: EntityGridEngagementFilter = .any
    public var rating: EntityGridRatingFilter = .any
    public var maximumRating: Int?
    public var taxonomy: EntityGridTaxonomyFilter = .any
    public var bookTypes = Set<String>()
    public var bookFormats = Set<String>()

    public init() {}

    public var activeCount: Int {
        (favoriteOnly ? 1 : 0)
            + (organization == .any ? 0 : 1)
            + (availability == .any && acquisitionStatus == nil ? 0 : 1)
            + (engagement == .any ? 0 : 1)
            + (rating == .any && maximumRating == nil ? 0 : 1)
            + (taxonomy == .any ? 0 : 1)
            + (bookTypes.isEmpty ? 0 : 1)
            + (bookFormats.isEmpty ? 0 : 1)
    }
}
