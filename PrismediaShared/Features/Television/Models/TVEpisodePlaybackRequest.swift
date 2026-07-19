import Foundation

struct TVEpisodePlaybackRequest: Identifiable, Equatable, Sendable {
    let id: UUID
    let episodeID: UUID

    init(episodeID: UUID, id: UUID = UUID()) {
        self.id = id
        self.episodeID = episodeID
    }
}
