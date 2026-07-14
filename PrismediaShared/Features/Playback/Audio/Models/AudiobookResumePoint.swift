import Foundation

public struct AudiobookResumePoint: Equatable, Sendable {
    public let trackID: UUID
    public let trackOffsetSeconds: Double

    public init(trackID: UUID, trackOffsetSeconds: Double) {
        self.trackID = trackID
        self.trackOffsetSeconds = trackOffsetSeconds
    }
}
