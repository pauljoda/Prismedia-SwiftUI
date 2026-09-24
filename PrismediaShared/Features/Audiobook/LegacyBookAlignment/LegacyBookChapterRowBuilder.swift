import Foundation

/// Composes the reading/listening chapter rows from an older server's persisted chapter map, for
/// servers that do not serve the alignment projection (before 3.8). The map already merges the
/// user's explicit picks with the scan-computed automatic title matches, so this builder only
/// applies it — no title matching runs on the client. Removed with the legacy folder.
struct LegacyBookChapterRowBuilder: Sendable {
    // MARK: - Actions - Rows

    func build(
        readableChapters: [ReadableBookChapter],
        audioTracks: [MusicTrack],
        audioChapters: [BookAudioChapter] = [],
        explicitMappings: [BookChapterAudioMapping] = []
    ) -> [BookChapterMapping] {
        let readable = readableChapters.sorted(by: readableChapterSort)
        let tracks = audioTracks.sorted(by: audioTrackSort)
        let candidates = BookAudioChapter.catalog(audioTracks: tracks, audioChapters: audioChapters)
        var consumedCandidateIndexes = Set<Int>()
        var matches: [String: Int] = [:]

        let readableIDs = Set(readable.map(\.id))
        let candidateIndexByIdentity = Dictionary(
            candidates.enumerated().map { ($1.identity, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        let trackByID = Dictionary(tracks.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        for mapping in explicitMappings {
            guard readableIDs.contains(mapping.readableChapterKey),
                matches[mapping.readableChapterKey] == nil,
                let index = candidateIndexByIdentity[BookAudioChapter(
                    audioTrackID: mapping.audioTrackID,
                    audioMarkerID: mapping.audioMarkerID,
                    title: "",
                    startSeconds: 0,
                    endSeconds: nil
                ).identity],
                !consumedCandidateIndexes.contains(index)
            else { continue }
            matches[mapping.readableChapterKey] = index
            consumedCandidateIndexes.insert(index)
        }

        var rows = readable.map { chapter in
            let candidate = matches[chapter.id].map { candidates[$0] }
            let track = candidate.flatMap { trackByID[$0.audioTrackID] }
            return BookChapterMapping(
                id: "read-\(chapter.id)-\(chapter.order)",
                title: chapter.title,
                order: chapter.order,
                depth: chapter.depth,
                readTarget: chapter.target,
                readStartFraction: chapter.startFraction,
                readEndFraction: chapter.endFraction,
                readPageCount: chapter.pageCount,
                audioTrack: track,
                audioMarkerID: candidate?.audioMarkerID,
                audioStartSeconds: candidate?.startSeconds,
                audioEndSeconds: candidate?.endSeconds
            )
        }

        var nextOrder = readable.count
        for index in candidates.indices where !consumedCandidateIndexes.contains(index) {
            let candidate = candidates[index]
            guard let track = trackByID[candidate.audioTrackID] else { continue }
            rows.append(
                BookChapterMapping(
                    id: "audio-\(candidate.identity.lowercased())",
                    title: candidate.title,
                    order: nextOrder,
                    depth: 0,
                    readTarget: nil,
                    readStartFraction: nil,
                    readEndFraction: nil,
                    readPageCount: nil,
                    audioTrack: track,
                    audioMarkerID: candidate.audioMarkerID,
                    audioStartSeconds: candidate.startSeconds,
                    audioEndSeconds: candidate.endSeconds
                )
            )
            nextOrder += 1
        }

        return rows
    }

    private func readableChapterSort(_ lhs: ReadableBookChapter, _ rhs: ReadableBookChapter) -> Bool {
        (lhs.order, lhs.title, lhs.id) < (rhs.order, rhs.title, rhs.id)
    }

    private func audioTrackSort(_ lhs: MusicTrack, _ rhs: MusicTrack) -> Bool {
        (lhs.sortOrder, lhs.title, lhs.id.uuidString)
            < (rhs.sortOrder, rhs.title, rhs.id.uuidString)
    }
}
