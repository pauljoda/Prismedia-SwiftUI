import Foundation

struct EntityPlaybackUpdateRequest: Encodable, Sendable {
    let resumeSeconds: Double
    let completed: Bool
}
