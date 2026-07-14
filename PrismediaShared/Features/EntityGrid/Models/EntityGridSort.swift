public enum EntityGridSort: String, CaseIterable, Codable, Hashable, Sendable, Identifiable {
    case title
    case added
    case rating
    case random
    case references

    public var id: String { rawValue }

    public var defaultDescending: Bool {
        switch self {
        case .added, .rating, .references: true
        case .title, .random: false
        }
    }

    public var label: String {
        switch self {
        case .title: "Title"
        case .added: "Date Added"
        case .rating: "Rating"
        case .random: "Random"
        case .references: "References"
        }
    }
}
