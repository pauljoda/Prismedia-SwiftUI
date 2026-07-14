import Foundation

public struct EntityPlaybackProgressUpdate: Equatable, Sendable {
    public let entityID: UUID
    public let resumeSeconds: Double
    public let completed: Bool

    public init(entityID: UUID, resumeSeconds: Double, completed: Bool) {
        self.entityID = entityID
        self.resumeSeconds = resumeSeconds
        self.completed = completed
    }
}
