import Foundation

struct TVEpisodeSelectionDecision: Equatable, Sendable {
    let episodeID: UUID
    let shouldPrewarmDetail: Bool
    let shouldPresentFullscreen: Bool
}
