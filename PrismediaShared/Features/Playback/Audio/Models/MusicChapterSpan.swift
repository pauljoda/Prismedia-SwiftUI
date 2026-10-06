import Foundation

/// One embedded chapter as the span of its file it plays as. Spans are contiguous: the first starts at
/// 0, each ends where the next begins, and the last runs to the end of the file, so every instant of
/// the file belongs to exactly one chapter.
public struct MusicChapterSpan: Equatable, Hashable, Sendable {
    /// Seconds into a chapter after which Previous restarts it instead of stepping back a chapter.
    public static let restartThresholdSeconds = 3.0

    public let markerID: UUID
    public let title: String
    /// Zero-based position among the file's chapters.
    public let index: Int
    public let startSeconds: Double
    /// Span end; nil only for the last chapter while the file's duration is unknown.
    public let endSeconds: Double?

    public init(markerID: UUID, title: String, index: Int, startSeconds: Double, endSeconds: Double?) {
        self.markerID = markerID
        self.title = title
        self.index = index
        self.startSeconds = startSeconds
        self.endSeconds = endSeconds
    }

    /// The spans a file's embedded chapters play as. A file with fewer than two chapters plays whole,
    /// so it has no spans. `duration` is the file's known length, preferred over a declared last end.
    public static func spans(of track: MusicTrack?, duration: Double? = nil) -> [MusicChapterSpan] {
        guard let track else { return [] }
        let knownDuration = positive(duration) ?? positive(track.duration)
        var starts = Set<Double>()
        let chapters = track.chapters
            .filter { chapter in
                guard chapter.startSeconds.isFinite else { return false }
                guard let knownDuration else { return true }
                return chapter.startSeconds < knownDuration
            }
            .sorted { $0.startSeconds < $1.startSeconds }
            .filter { starts.insert($0.startSeconds).inserted }
        guard chapters.count >= 2 else { return [] }

        return chapters.enumerated().map { index, chapter in
            let nextStart = index + 1 < chapters.count ? chapters[index + 1].startSeconds : nil
            return MusicChapterSpan(
                markerID: chapter.markerID,
                title: chapter.title,
                index: index,
                startSeconds: index == 0 ? 0 : chapter.startSeconds,
                endSeconds: nextStart ?? knownDuration ?? positive(chapter.endSeconds)
            )
        }
    }

    /// The span playing at `seconds` of its file; the first span before any chapter begins.
    public static func span(in spans: [MusicChapterSpan], at seconds: Double) -> MusicChapterSpan? {
        let position = seconds.isFinite ? seconds : 0
        return spans.last { $0.startSeconds <= position } ?? spans.first
    }

    private static func positive(_ value: Double?) -> Double? {
        guard let value, value.isFinite, value > 0 else { return nil }
        return value
    }
}
