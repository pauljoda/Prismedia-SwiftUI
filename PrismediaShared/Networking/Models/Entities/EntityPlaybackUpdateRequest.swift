import Foundation

struct EntityPlaybackUpdateRequest: Encodable, Sendable {
    let resumeSeconds: Double?
    let durationSeconds: Double?
    let completed: Bool?
    let utcOffsetMinutes: Int
}
