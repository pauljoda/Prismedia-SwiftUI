import Foundation

public struct EntityPlaybackCapability: Decodable, Hashable, Sendable {
    public let playCount: Int
    public let skipCount: Int
    public let playDurationSeconds: Double
    public let resumeSeconds: Double
    public let lastPlayedAt: String?
    public let completedAt: String?

    private enum CodingKeys: String, CodingKey {
        case playCount
        case skipCount
        case playDurationSeconds
        case resumeSeconds
        case lastPlayedAt
        case completedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        playCount = try container.decodeFlexibleInt(forKey: .playCount)
        skipCount = try container.decodeFlexibleInt(forKey: .skipCount)
        playDurationSeconds = try container.decodeFlexibleDouble(forKey: .playDurationSeconds)
        resumeSeconds = try container.decodeFlexibleDouble(forKey: .resumeSeconds)
        lastPlayedAt = try container.decodeIfPresent(String.self, forKey: .lastPlayedAt)
        completedAt = try container.decodeIfPresent(String.self, forKey: .completedAt)
    }
}
