import Foundation

public struct MusicPlaybackContext: Codable, Equatable, Sendable {
    public let playbackOwnerEntityID: UUID?
    public let playbackOwnerTitle: String?
    public let playbackOwnerEntityKind: EntityKind?

    public init(
        playbackOwnerEntityID: UUID? = nil,
        playbackOwnerTitle: String? = nil,
        playbackOwnerEntityKind: EntityKind? = nil
    ) {
        self.playbackOwnerEntityID = playbackOwnerEntityID
        self.playbackOwnerTitle = playbackOwnerTitle
        self.playbackOwnerEntityKind = playbackOwnerEntityKind
    }

    public var isAudiobook: Bool {
        playbackOwnerEntityID != nil && playbackOwnerEntityKind == .book
    }
}
