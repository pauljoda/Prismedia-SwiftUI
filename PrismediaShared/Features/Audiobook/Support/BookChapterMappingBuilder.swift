import Foundation

/// Composes the reading/listening chapter rows from the server-persisted chapter map. The map
/// already merges the user's explicit picks with the scan-computed automatic title matches, so
/// this builder only applies it — no title matching runs on the client anymore.
struct BookChapterMappingBuilder: Sendable {
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
        let candidateIndexByIdentity = Dictionary(uniqueKeysWithValues: candidates.enumerated().map { ($1.identity, $0) })
        let trackByID = Dictionary(uniqueKeysWithValues: tracks.map { ($0.id, $0) })
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

    private func audioTrackSort(_ lhs: MusicTrack, _ rhs: MusicTrack) -> Bool {
        (lhs.sortOrder, lhs.title, lhs.id.uuidString)
            < (rhs.sortOrder, rhs.title, rhs.id.uuidString)
    }
}
