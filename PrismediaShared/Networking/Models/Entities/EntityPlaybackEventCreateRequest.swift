import Foundation

struct EntityPlaybackEventCreateRequest: Encodable, Sendable {
    let kind: PlaybackEventKind
    let occurredAt: Date?
    let positionSeconds: Double?
    let durationSeconds: Double?
}
