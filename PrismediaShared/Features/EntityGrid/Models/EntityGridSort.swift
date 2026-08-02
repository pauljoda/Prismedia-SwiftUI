public enum EntityGridSort: String, CaseIterable, Codable, Hashable, Sendable, Identifiable {
    case title
    case index = "sort-order"
    case added = "date-added"
    case lastActive = "last-active"
    case rating
    case random
    case references

    public var id: String { rawValue }

    public var defaultDescending: Bool {
        false
    }

    public var label: String {
        switch self {
        case .title: "Title"
        case .index: "Index"
        case .added: "Date Added"
        case .lastActive: "Last Active"
        case .rating: "Rating"
        case .random: "Random"
        case .references: "References"
        }
    }
}
