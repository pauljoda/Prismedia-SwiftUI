public enum EntityGridAvailabilityFilter: String, CaseIterable, Hashable, Sendable, Identifiable {
    case any
    case onDisk
    case wanted
    public var id: String { rawValue }
}
