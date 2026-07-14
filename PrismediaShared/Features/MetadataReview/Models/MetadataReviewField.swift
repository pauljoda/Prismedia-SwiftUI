import Foundation

public enum MetadataReviewField: String, CaseIterable, Hashable, Sendable {
    case title
    case description
    case externalIDs = "externalIds"
    case urls
    case tags
    case studio
    case credits
    case dates
    case stats
    case positions
    case classification
    case images

    public var label: String {
        switch self {
        case .title: "Title"
        case .description: "Description"
        case .externalIDs: "Provider IDs"
        case .urls: "Links"
        case .tags: "Tags"
        case .studio: "Studio"
        case .credits: "Credits"
        case .dates: "Dates"
        case .stats: "Stats"
        case .positions: "Sort order"
        case .classification: "Classification"
        case .images: "Artwork"
        }
    }
}
