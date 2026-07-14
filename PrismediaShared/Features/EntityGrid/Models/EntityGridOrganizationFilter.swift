public enum EntityGridOrganizationFilter: String, CaseIterable, Codable, Hashable, Sendable, Identifiable {
    case any
    case organized
    case unorganized
    public var id: String { rawValue }
}
