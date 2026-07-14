import Foundation

/// One `/api/entities`-shaped list request (collections use their own path but
/// share the response shape).
public struct EntityListQuery: Hashable, Sendable {
    public var path: String
    public var kind: EntityKind?
    public var kinds: [EntityKind]
    public var sort: String?
    public var sortDescending: Bool
    public var seed: Int?
    public var favorite: Bool?
    public var organized: Bool?
    public var ratingMin: Int?
    public var ratingMax: Int?
    public var unrated: Bool?
    public var status: String?
    public var bookType: String?
    public var bookFormat: String?
    public var nsfw: Bool?
    public var hasFile: Bool?
    public var played: Bool?
    public var orphaned: Bool?
    public var wanted: Bool?
    public var acquisitionStatus: AcquisitionStatus?
    public var cursor: String?
    /// Native lists are SFW-only unless a future user-facing preference opts in.
    public var hideNsfw: Bool

    public init(
        path: String = "/api/entities",
        kind: EntityKind? = nil,
        kinds: [EntityKind] = [],
        sort: String? = nil,
        sortDescending: Bool = true,
        seed: Int? = nil,
        favorite: Bool? = nil,
        organized: Bool? = nil,
        ratingMin: Int? = nil,
        ratingMax: Int? = nil,
        unrated: Bool? = nil,
        status: String? = nil,
        bookType: String? = nil,
        bookFormat: String? = nil,
        nsfw: Bool? = nil,
        hasFile: Bool? = nil,
        played: Bool? = nil,
        orphaned: Bool? = nil,
        wanted: Bool? = nil,
        acquisitionStatus: AcquisitionStatus? = nil,
        cursor: String? = nil,
        hideNsfw: Bool = true
    ) {
        self.path = path
        self.kind = kind
        self.kinds = kinds
        self.sort = sort
        self.sortDescending = sortDescending
        self.seed = seed
        self.favorite = favorite
        self.organized = organized
        self.ratingMin = ratingMin
        self.ratingMax = ratingMax
        self.unrated = unrated
        self.status = status
        self.bookType = bookType
        self.bookFormat = bookFormat
        self.nsfw = nsfw
        self.hasFile = hasFile
        self.played = played
        self.orphaned = orphaned
        self.wanted = wanted
        self.acquisitionStatus = acquisitionStatus
        self.cursor = cursor
        self.hideNsfw = hideNsfw
    }

    public func queryItems(limit: Int, search: String?) -> [URLQueryItem] {
        var items = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "hideNsfw", value: hideNsfw ? "true" : "false"),
        ]

        // The repository's explicit `nsfw` filter remains effective even when
        // an authenticated server bypasses its higher-level visibility policy.
        let requestedKinds = kind.map { [$0] } ?? kinds
        if !requestedKinds.isEmpty {
            items.append(
                URLQueryItem(
                    name: "kind",
                    value: requestedKinds.map(\.rawValue).joined(separator: ",")
                ))
        }
        if let sort {
            items.append(URLQueryItem(name: "sort", value: sort))
            items.append(URLQueryItem(name: "sortDir", value: sortDescending ? "desc" : "asc"))
        }
        if let seed { items.append(URLQueryItem(name: "seed", value: String(seed))) }
        if let favorite { items.append(URLQueryItem(name: "favorite", value: String(favorite))) }
        if let organized { items.append(URLQueryItem(name: "organized", value: String(organized))) }
        if let ratingMin { items.append(URLQueryItem(name: "ratingMin", value: String(ratingMin))) }
        if let ratingMax { items.append(URLQueryItem(name: "ratingMax", value: String(ratingMax))) }
        if let unrated { items.append(URLQueryItem(name: "unrated", value: String(unrated))) }
        if let status { items.append(URLQueryItem(name: "status", value: status)) }
        if let bookType {
            items.append(URLQueryItem(name: "bookType", value: bookType))
        }
        if let bookFormat {
            items.append(URLQueryItem(name: "bookFormat", value: bookFormat))
        }
        if let nsfw { items.append(URLQueryItem(name: "nsfw", value: String(nsfw))) }
        if let hasFile { items.append(URLQueryItem(name: "hasFile", value: String(hasFile))) }
        if let played { items.append(URLQueryItem(name: "played", value: String(played))) }
        if let orphaned { items.append(URLQueryItem(name: "orphaned", value: String(orphaned))) }
        if let wanted { items.append(URLQueryItem(name: "wanted", value: String(wanted))) }
        if let acquisitionStatus {
            items.append(URLQueryItem(name: "acquisitionStatus", value: acquisitionStatus.rawValue))
        }
        if let cursor, !cursor.isEmpty {
            items.append(URLQueryItem(name: "cursor", value: cursor))
        }
        if let search, !search.isEmpty {
            items.append(URLQueryItem(name: "query", value: search))
        }

        return items
    }

    mutating func applyNsfwPreference(allowsNsfwContent: Bool) {
        hideNsfw = !allowsNsfwContent
        if !allowsNsfwContent {
            nsfw = false
        }
    }
}
