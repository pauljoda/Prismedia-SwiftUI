import Foundation

/// One provider episode represented by the same physical source file as another episode.
public struct EntitySharedSourceEpisode: Decodable, Hashable, Sendable {
    public let id: UUID
    public let title: String
    public let seasonNumber: Int?
    public let episodeNumber: Int?

    public init(
        id: UUID,
        title: String,
        seasonNumber: Int? = nil,
        episodeNumber: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.seasonNumber = seasonNumber
        self.episodeNumber = episodeNumber
    }
}
