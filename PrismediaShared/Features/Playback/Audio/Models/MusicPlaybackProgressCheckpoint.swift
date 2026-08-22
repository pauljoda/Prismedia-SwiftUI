import Foundation

public struct MusicPlaybackProgressCheckpoint: Codable, Equatable, Sendable {
    public let currentTrackID: UUID?
    public let elapsedTime: Double
    public let mappedProgressCompleted: Bool?

    private enum CodingKeys: String, CodingKey {
        case currentTrackID, elapsedTime, mappedProgressCompleted
        case legacyAudiobookCompleted = "audiobookCompleted"
    }

    public init(
        currentTrackID: UUID?,
        elapsedTime: Double,
        mappedProgressCompleted: Bool?
    ) {
        self.currentTrackID = currentTrackID
        self.elapsedTime = max(0, elapsedTime.isFinite ? elapsedTime : 0)
        self.mappedProgressCompleted = mappedProgressCompleted
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        currentTrackID = try container.decodeIfPresent(UUID.self, forKey: .currentTrackID)
        let elapsedTime = try container.decode(Double.self, forKey: .elapsedTime)
        self.elapsedTime = max(0, elapsedTime.isFinite ? elapsedTime : 0)
        mappedProgressCompleted = try container.decodeIfPresent(
            Bool.self,
            forKey: .mappedProgressCompleted
        ) ?? container.decodeIfPresent(Bool.self, forKey: .legacyAudiobookCompleted)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(currentTrackID, forKey: .currentTrackID)
        try container.encode(elapsedTime, forKey: .elapsedTime)
        try container.encodeIfPresent(mappedProgressCompleted, forKey: .mappedProgressCompleted)
    }
}
