enum TVSeasonBoundaryDirection: Hashable {
    case previous
    case next

    var title: String {
        switch self {
        case .previous: "Previous Season"
        case .next: "Next Season"
        }
    }

    var symbolName: String {
        switch self {
        case .previous: "chevron.left"
        case .next: "chevron.right"
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .previous: "tv.seasons-detail.previous-season"
        case .next: "tv.seasons-detail.next-season"
        }
    }
}
