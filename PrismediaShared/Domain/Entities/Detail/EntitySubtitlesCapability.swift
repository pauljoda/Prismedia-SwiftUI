import Foundation

/// Available subtitles and the time they were last extracted from source media.
public struct EntitySubtitlesCapability: Decodable, Hashable, Sendable {
    public let items: [EntitySubtitle]
    public let extractedAt: String?
}
