import Foundation

/// Playback-sized metadata for one Prismedia audio track.
public struct MusicTrack: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public let title: String
    public let artist: String?
    public let album: String?
    public let artworkPath: String?
    public let duration: Double?
    public let discNumber: Int?
    public let discTitle: String?
    public let trackNumber: Int?
    public let sortOrder: Int
    public let isWanted: Bool

    public var isPlayable: Bool { !isWanted }

    public init(
        id: UUID,
        title: String,
        artist: String? = nil,
        album: String? = nil,
        artworkPath: String? = nil,
        duration: Double? = nil,
        discNumber: Int? = nil,
        discTitle: String? = nil,
        trackNumber: Int? = nil,
        sortOrder: Int = 0,
        isWanted: Bool = false
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.artworkPath = artworkPath
        self.duration = duration
        self.discNumber = discNumber
        self.discTitle = discTitle
        self.trackNumber = trackNumber
        self.sortOrder = sortOrder
        self.isWanted = isWanted
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case artist
        case album
        case artworkPath
        case duration
        case discNumber
        case discTitle
        case trackNumber
        case sortOrder
        case isWanted
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        artist = try container.decodeIfPresent(String.self, forKey: .artist)
        album = try container.decodeIfPresent(String.self, forKey: .album)
        artworkPath = try container.decodeIfPresent(String.self, forKey: .artworkPath)
        duration = try container.decodeIfPresent(Double.self, forKey: .duration)
        discNumber = try container.decodeIfPresent(Int.self, forKey: .discNumber)
        discTitle = try container.decodeIfPresent(String.self, forKey: .discTitle)
        trackNumber = try container.decodeIfPresent(Int.self, forKey: .trackNumber)
        sortOrder = try container.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
        isWanted = try container.decodeIfPresent(Bool.self, forKey: .isWanted) ?? false
    }
}
