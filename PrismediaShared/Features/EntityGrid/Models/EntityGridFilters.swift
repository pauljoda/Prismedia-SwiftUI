public struct EntityGridFilters: Codable, Hashable, Sendable {
    public var favoriteOnly = false
    public var organization: EntityGridOrganizationFilter = .any
    public var availability: EntityGridAvailabilityFilter = .any
    public var includeWanted: Bool
    public var acquisitionStatus: AcquisitionStatus?
    public var engagement: EntityGridEngagementFilter = .any
    public var rating: EntityGridRatingFilter = .any
    public var maximumRating: Int?
    public var taxonomy: EntityGridTaxonomyFilter = .any
    public var bookTypes = Set<String>()
    public var bookFormats = Set<String>()

    public init(includeWanted: Bool = EntityGridFilters.defaultIncludeWanted) {
        self.includeWanted = includeWanted
    }

    public static var defaultIncludeWanted: Bool {
        #if os(tvOS)
            false
        #else
            true
        #endif
    }

    public var activeCount: Int {
        (favoriteOnly ? 1 : 0)
            + (organization == .any ? 0 : 1)
            + (availability == .any && acquisitionStatus == nil ? 0 : 1)
            + (includeWanted == Self.defaultIncludeWanted ? 0 : 1)
            + (engagement == .any ? 0 : 1)
            + (rating == .any && maximumRating == nil ? 0 : 1)
            + (taxonomy == .any ? 0 : 1)
            + (bookTypes.isEmpty ? 0 : 1)
            + (bookFormats.isEmpty ? 0 : 1)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        favoriteOnly = try container.decodeIfPresent(Bool.self, forKey: .favoriteOnly) ?? false
        organization =
            try container.decodeIfPresent(EntityGridOrganizationFilter.self, forKey: .organization) ?? .any
        availability =
            try container.decodeIfPresent(EntityGridAvailabilityFilter.self, forKey: .availability) ?? .any
        includeWanted = try container.decodeIfPresent(Bool.self, forKey: .includeWanted) ?? Self.defaultIncludeWanted
        acquisitionStatus = try container.decodeIfPresent(AcquisitionStatus.self, forKey: .acquisitionStatus)
        engagement =
            try container.decodeIfPresent(EntityGridEngagementFilter.self, forKey: .engagement) ?? .any
        rating = try container.decodeIfPresent(EntityGridRatingFilter.self, forKey: .rating) ?? .any
        maximumRating = try container.decodeIfPresent(Int.self, forKey: .maximumRating)
        taxonomy = try container.decodeIfPresent(EntityGridTaxonomyFilter.self, forKey: .taxonomy) ?? .any
        bookTypes = try container.decodeIfPresent(Set<String>.self, forKey: .bookTypes) ?? []
        bookFormats = try container.decodeIfPresent(Set<String>.self, forKey: .bookFormats) ?? []
    }

    private enum CodingKeys: String, CodingKey {
        case favoriteOnly
        case organization
        case availability
        case includeWanted
        case acquisitionStatus
        case engagement
        case rating
        case maximumRating
        case taxonomy
        case bookTypes
        case bookFormats
    }
}
