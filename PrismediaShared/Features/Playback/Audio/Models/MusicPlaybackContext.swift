import Foundation

public struct MusicPlaybackContext: Codable, Equatable, Sendable {
    public let playbackOwnerEntityID: UUID?
    public let playbackOwnerTitle: String?
    public let playbackOwnerEntityKind: EntityKind?
    public let bookProgressMappings: [BookProgressTrackMapping]?
    public let preservesQueueOrder: Bool
    public let supportsPlaybackRate: Bool

    private enum CodingKeys: String, CodingKey {
        case playbackOwnerEntityID
        case playbackOwnerTitle
        case playbackOwnerEntityKind
        case bookProgressMappings
        case preservesQueueOrder
        case supportsPlaybackRate
    }

    public init(
        playbackOwnerEntityID: UUID? = nil,
        playbackOwnerTitle: String? = nil,
        playbackOwnerEntityKind: EntityKind? = nil,
        bookProgressMappings: [BookProgressTrackMapping]? = nil,
        preservesQueueOrder: Bool = false,
        supportsPlaybackRate: Bool = false
    ) {
        self.playbackOwnerEntityID = playbackOwnerEntityID
        self.playbackOwnerTitle = playbackOwnerTitle
        self.playbackOwnerEntityKind = playbackOwnerEntityKind
        self.bookProgressMappings = bookProgressMappings
        self.preservesQueueOrder = preservesQueueOrder
        self.supportsPlaybackRate = supportsPlaybackRate
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        playbackOwnerEntityID = try container.decodeIfPresent(UUID.self, forKey: .playbackOwnerEntityID)
        playbackOwnerTitle = try container.decodeIfPresent(String.self, forKey: .playbackOwnerTitle)
        playbackOwnerEntityKind = try container.decodeIfPresent(EntityKind.self, forKey: .playbackOwnerEntityKind)
        bookProgressMappings = try container.decodeIfPresent(
            [BookProgressTrackMapping].self,
            forKey: .bookProgressMappings
        )
        preservesQueueOrder = try container.decodeIfPresent(Bool.self, forKey: .preservesQueueOrder) ?? false
        supportsPlaybackRate = try container.decodeIfPresent(Bool.self, forKey: .supportsPlaybackRate) ?? false
    }

    /// Book-specific coordinate conversion stays outside the generic player policy.
    public var usesBookProgress: Bool {
        playbackOwnerEntityID != nil && bookProgressMappings?.isEmpty == false
    }
}
