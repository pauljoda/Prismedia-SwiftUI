public enum EntityGridRatingFilter: Codable, Hashable, Sendable {
    case any
    case unrated
    case atLeast(Int)
}
