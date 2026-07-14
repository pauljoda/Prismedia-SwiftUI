import Foundation

/// The user-owned portion of a grid query. Route constraints are intentionally
/// excluded so restoring one surface cannot turn a Comics grid into Books.
public struct EntityGridPreferences: Codable, Equatable, Sendable {
    public let displayMode: EntityGridDisplayMode
    public let density: EntityGridDensity
    public let pageSize: Int?
    public let sort: String?
    public let sortDescending: Bool
    public let favoriteOnly: Bool
    public let organization: String
    public let availability: String
    public let acquisitionStatus: String?
    public let engagement: String
    public let isUnrated: Bool
    public let minimumRating: Int?
    public let maximumRating: Int?
    public let taxonomy: String
    public let bookTypes: [String]
    public let bookFormats: [String]

    public init(
        controls: EntityGridControls,
        displayMode: EntityGridDisplayMode = .grid,
        density: EntityGridDensity = .standard,
        pageSize: Int? = nil
    ) {
        precondition(pageSize == nil || pageSize! > 0, "A persisted page size must be positive.")
        self.displayMode = displayMode
        self.density = density
        self.pageSize = pageSize
        sort = controls.sort?.rawValue
        sortDescending = controls.sortDescending
        favoriteOnly = controls.filters.favoriteOnly
        organization = controls.filters.organization.rawValue
        availability = controls.filters.availability.rawValue
        acquisitionStatus = controls.filters.acquisitionStatus?.rawValue
        engagement = controls.filters.engagement.rawValue
        switch controls.filters.rating {
        case .any:
            isUnrated = false
            minimumRating = nil
        case .unrated:
            isUnrated = true
            minimumRating = nil
        case .atLeast(let value):
            isUnrated = false
            minimumRating = value
        }
        maximumRating = controls.filters.maximumRating
        taxonomy = controls.filters.taxonomy.rawValue
        bookTypes = controls.filters.bookTypes.sorted()
        bookFormats = controls.filters.bookFormats.sorted()
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        displayMode = try container.decodeIfPresent(EntityGridDisplayMode.self, forKey: .displayMode) ?? .grid
        density = try container.decodeIfPresent(EntityGridDensity.self, forKey: .density) ?? .standard
        pageSize = try container.decodeIfPresent(Int.self, forKey: .pageSize)
        sort = try container.decodeIfPresent(String.self, forKey: .sort)
        sortDescending = try container.decodeIfPresent(Bool.self, forKey: .sortDescending) ?? true
        favoriteOnly = try container.decodeIfPresent(Bool.self, forKey: .favoriteOnly) ?? false
        organization = try container.decodeIfPresent(String.self, forKey: .organization) ?? "any"
        availability = try container.decodeIfPresent(String.self, forKey: .availability) ?? "any"
        acquisitionStatus = try container.decodeIfPresent(String.self, forKey: .acquisitionStatus)
        engagement = try container.decodeIfPresent(String.self, forKey: .engagement) ?? "any"
        isUnrated = try container.decodeIfPresent(Bool.self, forKey: .isUnrated) ?? false
        minimumRating = try container.decodeIfPresent(Int.self, forKey: .minimumRating)
        maximumRating = try container.decodeIfPresent(Int.self, forKey: .maximumRating)
        taxonomy = try container.decodeIfPresent(String.self, forKey: .taxonomy) ?? "any"
        bookTypes = try container.decodeIfPresent([String].self, forKey: .bookTypes) ?? []
        bookFormats = try container.decodeIfPresent([String].self, forKey: .bookFormats) ?? []
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(displayMode, forKey: .displayMode)
        try container.encode(density, forKey: .density)
        try container.encodeIfPresent(pageSize, forKey: .pageSize)
        try container.encodeIfPresent(sort, forKey: .sort)
        try container.encode(sortDescending, forKey: .sortDescending)
        try container.encode(favoriteOnly, forKey: .favoriteOnly)
        try container.encode(organization, forKey: .organization)
        try container.encode(availability, forKey: .availability)
        try container.encodeIfPresent(acquisitionStatus, forKey: .acquisitionStatus)
        try container.encode(engagement, forKey: .engagement)
        try container.encode(isUnrated, forKey: .isUnrated)
        try container.encodeIfPresent(minimumRating, forKey: .minimumRating)
        try container.encodeIfPresent(maximumRating, forKey: .maximumRating)
        try container.encode(taxonomy, forKey: .taxonomy)
        try container.encode(bookTypes, forKey: .bookTypes)
        try container.encode(bookFormats, forKey: .bookFormats)
    }

    public func controls(baselineQuery: EntityListQuery) -> EntityGridControls {
        var controls = EntityGridControls(baselineQuery: baselineQuery)
        controls.sort = sort.flatMap(EntityGridSort.init(rawValue:)) ?? controls.sort
        controls.sortDescending = sortDescending
        controls.filters.favoriteOnly = favoriteOnly
        controls.filters.organization = EntityGridOrganizationFilter(rawValue: organization) ?? .any
        controls.filters.availability = EntityGridAvailabilityFilter(rawValue: availability) ?? .any
        controls.filters.acquisitionStatus = acquisitionStatus.map(AcquisitionStatus.init(rawValue:))
        controls.filters.engagement = EntityGridEngagementFilter(rawValue: engagement) ?? .any
        if isUnrated {
            controls.filters.rating = .unrated
        } else if let minimumRating {
            controls.filters.rating = .atLeast(minimumRating)
        } else {
            controls.filters.rating = .any
        }
        controls.filters.maximumRating = maximumRating
        controls.filters.taxonomy = EntityGridTaxonomyFilter(rawValue: taxonomy) ?? .any
        controls.filters.bookTypes = Set(bookTypes)
        controls.filters.bookFormats = Set(bookFormats)
        return controls
    }

    private enum CodingKeys: String, CodingKey {
        case displayMode
        case density
        case pageSize
        case sort
        case sortDescending
        case favoriteOnly
        case organization
        case availability
        case acquisitionStatus
        case engagement
        case isUnrated
        case minimumRating
        case maximumRating
        case taxonomy
        case bookTypes
        case bookFormats
    }
}
