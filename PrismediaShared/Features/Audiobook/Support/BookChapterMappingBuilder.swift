import Foundation

/// Builds the explicit chapter map a user asks for in the chapter-mapping editor. Pairing and
/// resume alignment are otherwise owned by the server.
struct BookChapterMappingBuilder: Sendable {
    // MARK: - Actions - Mapping

    /// Creates the explicit one-to-one map produced by the “Mark first chapter” workflow.
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
                audioMarkerID: candidate.audioMarkerID
            )
        }
    }

    private func readableChapterSort(_ lhs: ReadableBookChapter, _ rhs: ReadableBookChapter) -> Bool {
        (lhs.order, lhs.title, lhs.id) < (rhs.order, rhs.title, rhs.id)
    }
}
