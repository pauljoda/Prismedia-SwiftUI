import Foundation

/// User-scoped summary of opens, outcomes, active time, and timed resume for an Entity.
public struct EntityConsumptionCapability: Decodable, Hashable, Sendable {
    public let accessCount: Int
    public let completionCount: Int
    public let skipCount: Int
    public let activeSeconds: Double
    public let resumeSeconds: Double
    public let lastAccessedAt: String?
    public let lastActiveAt: String?
    public let completedAt: String?

    private enum CodingKeys: String, CodingKey {
        case accessCount
        case completionCount
        case skipCount
        case activeSeconds
        case resumeSeconds
        case lastAccessedAt
        case lastActiveAt
        case completedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accessCount = try container.decodeFlexibleInt(forKey: .accessCount)
        completionCount = try container.decodeFlexibleInt(forKey: .completionCount)
        skipCount = try container.decodeFlexibleInt(forKey: .skipCount)
        activeSeconds = try container.decodeFlexibleDouble(forKey: .activeSeconds)
        resumeSeconds = try container.decodeFlexibleDouble(forKey: .resumeSeconds)
        lastAccessedAt = try container.decodeIfPresent(String.self, forKey: .lastAccessedAt)
        lastActiveAt = try container.decodeIfPresent(String.self, forKey: .lastActiveAt)
        completedAt = try container.decodeIfPresent(String.self, forKey: .completedAt)
    }
}
