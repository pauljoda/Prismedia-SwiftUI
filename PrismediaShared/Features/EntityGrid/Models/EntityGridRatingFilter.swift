public enum EntityGridRatingFilter: Hashable, Sendable {
    case any
    case unrated
    case atLeast(Int)
}
