import Foundation

enum TVEpisodeRailFocusTarget: Hashable {
    case previousSeason
    case episode(UUID)
    case nextSeason
}
