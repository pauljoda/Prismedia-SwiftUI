import Foundation

/// One entry the transport steps through: an embedded chapter of a file, or a whole file.
public struct MusicQueueEntry: Identifiable, Equatable, Sendable {
    public let track: MusicTrack
    /// The chapter this entry plays, or nil when the file plays whole.
    public let chapter: MusicChapterSpan?

    public var id: String {
        "\(track.id.uuidString):\(chapter?.markerID.uuidString ?? "whole")"
    }

    /// Title of the entry: its chapter, else its file.
    public var title: String {
        chapter?.title ?? track.title
    }

    public init(track: MusicTrack, chapter: MusicChapterSpan?) {
        self.track = track
        self.chapter = chapter
    }
}
