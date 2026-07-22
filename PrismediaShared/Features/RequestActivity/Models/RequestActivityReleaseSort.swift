import Foundation

enum RequestActivityReleaseSort: CaseIterable, Equatable, Sendable {
    case bestMatch
    case seedersDescending
    case seedersAscending
    case sizeDescending
    case sizeAscending
    case titleAscending
    case titleDescending
    case indexerAscending
    case indexerDescending

    var title: String {
        switch self {
        case .bestMatch: "Best Match"
        case .seedersDescending: "Most Seeders"
        case .seedersAscending: "Fewest Seeders"
        case .sizeDescending: "Largest"
        case .sizeAscending: "Smallest"
        case .titleAscending: "Title A–Z"
        case .titleDescending: "Title Z–A"
        case .indexerAscending: "Indexer A–Z"
        case .indexerDescending: "Indexer Z–A"
        }
    }
}
