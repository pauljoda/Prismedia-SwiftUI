import Foundation

/// Where the entry playing begins in its file, how long it is, and the position inside it. The entry
/// is the embedded chapter playing, or the whole file when it plays whole.
public struct MusicEntryPosition: Equatable, Sendable {
    /// Entry start inside its file.
    public let start: Double
    /// Entry length; 0 while it is unknown.
    public let duration: Double
    /// Position inside the entry.
    public let position: Double

    public init(start: Double, duration: Double, position: Double) {
        self.start = start
        self.duration = duration
        self.position = position
    }

    /// The entry playing at `fileTime` of a file `fileDuration` long. A chapter without a known end
    /// runs to the end of the file.
    public init(spans: [MusicChapterSpan], fileTime: Double, fileDuration: Double) {
        let chapter = MusicChapterSpan.span(in: spans, at: fileTime)
        let start = chapter?.startSeconds ?? 0
        let end = chapter?.endSeconds ?? fileDuration
        let duration = end.isFinite && end > start ? end - start : 0
        self.start = start
        self.duration = duration
        position = max(0, duration > 0 ? min(fileTime - start, duration) : fileTime - start)
    }
}
