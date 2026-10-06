import Foundation

/// One chapter embedded in an audio file, as a window of the file's own timeline.
public struct MusicTrackChapter: Codable, Hashable, Sendable {
    /// Persisted embedded chapter marker.
    public let markerID: UUID
    public let title: String
    /// Chapter start inside the file.
    public let startSeconds: Double
    /// Chapter end inside the file; nil when the server could not bound it.
    public let endSeconds: Double?

    public init(markerID: UUID, title: String, startSeconds: Double, endSeconds: Double? = nil) {
        self.markerID = markerID
        self.title = title
        self.startSeconds = startSeconds
        self.endSeconds = endSeconds
    }
}
