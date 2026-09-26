import Foundation

/// Builds the explicit chapter map a user asks for in the chapter-mapping editor. Pairing and
/// resume alignment are otherwise owned by the server.
struct BookChapterMappingBuilder: Sendable {
    // MARK: - Actions - Mapping

    /// Proposes the one-to-one map of the editor's “Fill in order from here” step: audio chapters in
    /// playback order pair with readable chapters in display order, starting at the chosen chapter.
    /// The proposal is reviewed pair by pair before it is used, and every pair is remembered as
    /// filled in order (never as picked by hand).
    func sequentialMappings(
        readableChapters: [ReadableBookChapter],
        audioTracks: [MusicTrack],
        audioChapters: [BookAudioChapter] = [],
        firstReadableChapterKey: String
    ) -> [BookChapterAudioMapping] {
        let readable = readableChapters.sorted(by: readableChapterSort)
        let candidates = BookAudioChapter.catalog(audioTracks: audioTracks, audioChapters: audioChapters)
        guard let firstIndex = readable.firstIndex(where: { $0.id == firstReadableChapterKey }) else {
            return []
        }

        return candidates.prefix(readable.count - firstIndex).enumerated().map { offset, candidate in
            BookChapterAudioMapping(
                readableChapterKey: readable[firstIndex + offset].id,
                audioTrackID: candidate.audioTrackID,
                origin: .ordered,
                audioMarkerID: candidate.audioMarkerID
            )
        }
    }

    private func readableChapterSort(_ lhs: ReadableBookChapter, _ rhs: ReadableBookChapter) -> Bool {
        (lhs.order, lhs.title, lhs.id) < (rhs.order, rhs.title, rhs.id)
    }
}
