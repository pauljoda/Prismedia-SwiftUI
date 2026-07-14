public enum EntityGridEngagementFilter: String, CaseIterable, Hashable, Sendable, Identifiable {
    case any
    case watched
    case unwatched
    case inProgress
    public var id: String { rawValue }
}
