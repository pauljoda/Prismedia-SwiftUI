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
        sortOrder: Int = 0
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
    }
}
