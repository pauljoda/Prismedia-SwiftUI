public enum EntityGridTaxonomyFilter: String, CaseIterable, Codable, Hashable, Sendable, Identifiable {
    case any
    case referenced
    case orphaned
    public var id: String { rawValue }
}
