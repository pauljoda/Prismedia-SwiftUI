import Foundation

public struct PlaybackStatisticsEvent: Decodable, Equatable, Sendable, Identifiable {
    public let id: UUID
    public let entityID: UUID
    public let entityKind: EntityKind
    public let entityTitle: String
    public let coverURL: String?
    public let kind: PlaybackEventKind
    public let occurredAt: Date
    public let positionSeconds: Double?
    public let durationSeconds: Double?

    private enum CodingKeys: String, CodingKey {
        case id, entityKind, entityTitle, kind, occurredAt, positionSeconds, durationSeconds
        case entityID = "entityId"
        case coverURL = "coverUrl"
    }
}
