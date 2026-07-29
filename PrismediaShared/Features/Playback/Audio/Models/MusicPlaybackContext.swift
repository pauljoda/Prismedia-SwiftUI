import Foundation

public struct MusicPlaybackContext: Codable, Equatable, Sendable {
    public let playbackOwnerEntityID: UUID?
    public let playbackOwnerTitle: String?
    public let playbackOwnerEntityKind: EntityKind?
    public let bookProgressMappings: [BookProgressTrackMapping]?

    public init(
        playbackOwnerEntityID: UUID? = nil,
        playbackOwnerTitle: String? = nil,
        playbackOwnerEntityKind: EntityKind? = nil,
        bookProgressMappings: [BookProgressTrackMapping]? = nil
    ) {
        self.playbackOwnerEntityID = playbackOwnerEntityID
        self.playbackOwnerTitle = playbackOwnerTitle
        self.playbackOwnerEntityKind = playbackOwnerEntityKind
        self.bookProgressMappings = bookProgressMappings
    }

    public var isAudiobook: Bool {
        playbackOwnerEntityID != nil && playbackOwnerEntityKind == .book
    }
}
