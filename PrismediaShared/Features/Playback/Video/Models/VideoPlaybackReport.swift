import Foundation

public struct VideoPlaybackReport: Encodable, Hashable, Sendable {
    public let entityID: UUID
    public let sessionID: String
    public let positionSeconds: Double
    public let durationSeconds: Double
    public let completed: Bool?
    public let activitySeconds: Double?
    public let utcOffsetMinutes: Int

    public init(
        entityID: UUID,
        sessionID: String,
        positionSeconds: Double,
        durationSeconds: Double,
        completed: Bool? = nil,
        activitySeconds: Double? = nil,
        utcOffsetMinutes: Int = TimeZone.current.secondsFromGMT() / 60
    ) {
        self.entityID = entityID
        self.sessionID = sessionID
        self.positionSeconds = positionSeconds.isFinite ? max(0, positionSeconds) : 0
        self.durationSeconds = durationSeconds.isFinite ? max(0, durationSeconds) : 0
        self.completed = completed
        self.activitySeconds = activitySeconds.flatMap {
            $0.isFinite && $0 > 0 ? min($0, 60) : nil
        }
        self.utcOffsetMinutes = utcOffsetMinutes
    }

    private enum CodingKeys: String, CodingKey {
        case entityID = "entityId"
        case sessionID = "sessionId"
        case positionSeconds
        case durationSeconds
        case completed
        case activitySeconds
        case utcOffsetMinutes
    }
}
