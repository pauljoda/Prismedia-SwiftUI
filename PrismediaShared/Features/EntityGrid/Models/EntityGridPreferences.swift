import Foundation

/// The user-owned portion of a grid query. Route constraints and random state
/// are intentionally excluded so one surface cannot alter another surface's contract.
public struct EntityGridPreferences: Codable, Equatable, Sendable {
    public let displayMode: EntityGridDisplayMode
    public let density: EntityGridDensity
    public let pageSize: Int?

    private let savedControls: EntityGridControls

    public var sort: String? { savedControls.sort?.rawValue }
    public var sortDescending: Bool { savedControls.sortDescending }
    public var favoriteOnly: Bool { savedControls.filters.favoriteOnly }
    public var organization: String { savedControls.filters.organization.rawValue }
    public var availability: String { savedControls.filters.availability.rawValue }
    public var includeWanted: Bool { savedControls.filters.includeWanted }
    public var acquisitionStatus: String? { savedControls.filters.acquisitionStatus?.rawValue }
    public var engagement: String { savedControls.filters.engagement.rawValue }
    public var isUnrated: Bool { savedControls.filters.rating == .unrated }
    public var minimumRating: Int? {
        guard case .atLeast(let value) = savedControls.filters.rating else { return nil }
        return value
    }
    public var maximumRating: Int? { savedControls.filters.maximumRating }
    public var taxonomy: String { savedControls.filters.taxonomy.rawValue }
    public var bookTypes: [String] { savedControls.filters.bookTypes.sorted() }
    public var bookFormats: [String] { savedControls.filters.bookFormats.sorted() }

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
        savedControls = Self.normalized(controls)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        displayMode = try container.decodeIfPresent(EntityGridDisplayMode.self, forKey: .displayMode) ?? .grid
        density = try container.decodeIfPresent(EntityGridDensity.self, forKey: .density) ?? .standard
        pageSize = try container.decodeIfPresent(Int.self, forKey: .pageSize)
        if let controls = try container.decodeIfPresent(EntityGridControls.self, forKey: .controls) {
            savedControls = Self.normalized(controls)
        } else {
            savedControls = Self.normalized(try Self.decodeLegacyControls(from: container))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(displayMode, forKey: .displayMode)
        try container.encode(density, forKey: .density)
        try container.encodeIfPresent(pageSize, forKey: .pageSize)
        try container.encode(savedControls, forKey: .controls)
    }

    public func controls(baselineQuery _: EntityListQuery) -> EntityGridControls {
        var controls = savedControls
        controls.randomSeed = EntityGridControls.nextRandomSeed()
        return controls
    }

    private static func normalized(_ controls: EntityGridControls) -> EntityGridControls {
        var controls = controls
        controls.randomSeed = 0
        return controls
    }

    private static func decodeLegacyControls(
        from container: KeyedDecodingContainer<CodingKeys>
    ) throws -> EntityGridControls {
        var controls = EntityGridControls(baselineQuery: EntityListQuery())
        controls.sort = try container.decodeIfPresent(String.self, forKey: .sort).flatMap(EntityGridSort.init)
        controls.sortDescending = try container.decodeIfPresent(Bool.self, forKey: .sortDescending) ?? true
        controls.filters.favoriteOnly = try container.decodeIfPresent(Bool.self, forKey: .favoriteOnly) ?? false
        controls.filters.organization =
            try container.decodeIfPresent(String.self, forKey: .organization)
            .flatMap(EntityGridOrganizationFilter.init) ?? .any
        controls.filters.availability =
            try container.decodeIfPresent(String.self, forKey: .availability)
            .flatMap(EntityGridAvailabilityFilter.init) ?? .any
        controls.filters.acquisitionStatus = try container.decodeIfPresent(String.self, forKey: .acquisitionStatus)
            .map(AcquisitionStatus.init)
        controls.filters.engagement =
            try container.decodeIfPresent(String.self, forKey: .engagement)
            .flatMap(EntityGridEngagementFilter.init) ?? .any
        let isUnrated = try container.decodeIfPresent(Bool.self, forKey: .isUnrated) ?? false
        let minimumRating = try container.decodeIfPresent(Int.self, forKey: .minimumRating)
        controls.filters.rating = isUnrated ? .unrated : minimumRating.map(EntityGridRatingFilter.atLeast) ?? .any
        controls.filters.maximumRating = try container.decodeIfPresent(Int.self, forKey: .maximumRating)
        controls.filters.taxonomy =
            try container.decodeIfPresent(String.self, forKey: .taxonomy)
            .flatMap(EntityGridTaxonomyFilter.init) ?? .any
        controls.filters.bookTypes = Set(try container.decodeIfPresent([String].self, forKey: .bookTypes) ?? [])
        controls.filters.bookFormats = Set(try container.decodeIfPresent([String].self, forKey: .bookFormats) ?? [])
        return controls
    }

    private enum CodingKeys: String, CodingKey {
        case displayMode
        case density
        case pageSize
        case controls
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
