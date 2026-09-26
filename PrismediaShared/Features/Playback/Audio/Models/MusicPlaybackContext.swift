import Foundation

/// The owner of a player queue, such as the Book whose audiobook parts are playing, and how the
/// player reports progress to it. Persisted with the restorable queue.
public struct MusicPlaybackContext: Codable, Equatable, Sendable {
    // MARK: - Variables

    /// Client-built cursor mappings for servers before 3.8. Kept decodable for one release.
    public let progressMappings: [PlaybackProgressMapping]?
    public let playbackOwnerEntityID: UUID?
    public let playbackOwnerTitle: String?
    public let playbackOwnerEntityKind: EntityKind?
    /// Modality the player reports to the owner. `listening` sends the exact track position on
    /// every heartbeat and lets the server (3.8+) place the owner's cursor.
    public let progressModality: ConsumptionModality?
    public let preservesQueueOrder: Bool
    public let supportsPlaybackRate: Bool

    /// Whether playback reports progress to the owning Entity instead of each track.
    public var usesMappedProgress: Bool {
        guard playbackOwnerEntityID != nil else { return false }
        return reportsListeningCheckpoints || progressMappings?.isEmpty == false
    }

    /// Whether playback reports exact listening checkpoints to the owner.
    public var reportsListeningCheckpoints: Bool {
        playbackOwnerEntityID != nil && progressModality == .listening
    }

    // MARK: - Initializers

    public init(
        playbackOwnerEntityID: UUID? = nil,
        playbackOwnerTitle: String? = nil,
        playbackOwnerEntityKind: EntityKind? = nil,
        progressModality: ConsumptionModality? = nil,
        progressMappings: [PlaybackProgressMapping]? = nil,
        preservesQueueOrder: Bool = false,
        supportsPlaybackRate: Bool = false
    ) {
        self.playbackOwnerEntityID = playbackOwnerEntityID
        self.playbackOwnerTitle = playbackOwnerTitle
        self.playbackOwnerEntityKind = playbackOwnerEntityKind
        self.progressModality = progressModality
        self.progressMappings = progressMappings
        self.preservesQueueOrder = preservesQueueOrder
        self.supportsPlaybackRate = supportsPlaybackRate
    }

    private enum CodingKeys: String, CodingKey {
        case playbackOwnerEntityID
        case playbackOwnerTitle
        case playbackOwnerEntityKind
        case progressModality
        case progressMappings
        case legacyBookProgressMappings = "bookProgressMappings"
        case preservesQueueOrder
        case supportsPlaybackRate
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        playbackOwnerEntityID = try container.decodeIfPresent(UUID.self, forKey: .playbackOwnerEntityID)
        playbackOwnerTitle = try container.decodeIfPresent(String.self, forKey: .playbackOwnerTitle)
        playbackOwnerEntityKind = try container.decodeIfPresent(EntityKind.self, forKey: .playbackOwnerEntityKind)
        progressModality = try container.decodeIfPresent(ConsumptionModality.self, forKey: .progressModality)
        progressMappings =
            try container.decodeIfPresent(
                [PlaybackProgressMapping].self,
                forKey: .progressMappings
            )
            ?? container.decodeIfPresent(
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
        try container.encodeIfPresent(progressModality, forKey: .progressModality)
        try container.encodeIfPresent(progressMappings, forKey: .progressMappings)
        try container.encode(preservesQueueOrder, forKey: .preservesQueueOrder)
        try container.encode(supportsPlaybackRate, forKey: .supportsPlaybackRate)
    }
}
