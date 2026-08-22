import Foundation

public struct MusicPlaybackContext: Codable, Equatable, Sendable {
    public let playbackOwnerEntityID: UUID?
    public let playbackOwnerTitle: String?
    public let playbackOwnerEntityKind: EntityKind?
    public let progressMappings: [PlaybackProgressMapping]?
    public let preservesQueueOrder: Bool
    public let supportsPlaybackRate: Bool

    private enum CodingKeys: String, CodingKey {
        case playbackOwnerEntityID
        case playbackOwnerTitle
        case playbackOwnerEntityKind
        case progressMappings
        case legacyBookProgressMappings = "bookProgressMappings"
        case preservesQueueOrder
        case supportsPlaybackRate
    }

    public init(
        playbackOwnerEntityID: UUID? = nil,
        playbackOwnerTitle: String? = nil,
        playbackOwnerEntityKind: EntityKind? = nil,
        progressMappings: [PlaybackProgressMapping]? = nil,
        preservesQueueOrder: Bool = false,
        supportsPlaybackRate: Bool = false
    ) {
        self.playbackOwnerEntityID = playbackOwnerEntityID
        self.playbackOwnerTitle = playbackOwnerTitle
        self.playbackOwnerEntityKind = playbackOwnerEntityKind
        self.progressMappings = progressMappings
        self.preservesQueueOrder = preservesQueueOrder
        self.supportsPlaybackRate = supportsPlaybackRate
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        playbackOwnerEntityID = try container.decodeIfPresent(UUID.self, forKey: .playbackOwnerEntityID)
        playbackOwnerTitle = try container.decodeIfPresent(String.self, forKey: .playbackOwnerTitle)
        playbackOwnerEntityKind = try container.decodeIfPresent(EntityKind.self, forKey: .playbackOwnerEntityKind)
        progressMappings = try container.decodeIfPresent(
            [PlaybackProgressMapping].self,
            forKey: .progressMappings
        ) ?? container.decodeIfPresent(
            [PlaybackProgressMapping].self,
            forKey: .legacyBookProgressMappings
        )
        preservesQueueOrder = try container.decodeIfPresent(Bool.self, forKey: .preservesQueueOrder) ?? false
        supportsPlaybackRate = try container.decodeIfPresent(Bool.self, forKey: .supportsPlaybackRate) ?? false
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(playbackOwnerEntityID, forKey: .playbackOwnerEntityID)
        try container.encodeIfPresent(playbackOwnerTitle, forKey: .playbackOwnerTitle)
        try container.encodeIfPresent(playbackOwnerEntityKind, forKey: .playbackOwnerEntityKind)
        try container.encodeIfPresent(progressMappings, forKey: .progressMappings)
        try container.encode(preservesQueueOrder, forKey: .preservesQueueOrder)
        try container.encode(supportsPlaybackRate, forKey: .supportsPlaybackRate)
    }

    public var usesMappedProgress: Bool {
        playbackOwnerEntityID != nil && progressMappings?.isEmpty == false
    }
}
