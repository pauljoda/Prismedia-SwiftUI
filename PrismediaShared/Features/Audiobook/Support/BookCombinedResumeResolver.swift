import Foundation

struct BookCombinedResumeResolver: Sendable {
    private let audioRunwaySeconds = 5.0

    func resolveReadingTarget(
        chapters: [BookChapterMapping],
        trackID: UUID,
        trackOffsetSeconds: Double
    ) -> BookReaderLocationTarget? {
        guard let chapter = chapters.first(where: { $0.audioTrack?.id == trackID }),
            case .epub(let location) = chapter.readTarget,
            let duration = chapter.audioTrack?.duration,
            duration.isFinite,
            duration > 0
        else { return nil }
        return BookReaderLocationTarget(
            location: location,
            progression: bounded(trackOffsetSeconds / duration)
        )
    }

    func resolveContinuation(
        chapters: [BookChapterMapping],
        mappings: [BookProgressTrackMapping],
        progress: EntityProgressCapability?
    ) -> BookCombinedResumeTarget? {
        if let progress, progress.completedAt == nil {
            guard let mapping = BookProgressMappingResolver().mapping(for: progress, in: mappings),
                let chapter = chapters.first(where: { $0.audioTrack?.id == mapping.trackID })
            else {
                // The readable cursor is authoritative when no audio part maps to it.
                return nil
            }
            return target(chapter: chapter, mapping: mapping, progress: progress)
        }

        guard let mapping = mappings.first,
            let chapter = chapters.first(where: { $0.audioTrack?.id == mapping.trackID })
        else { return nil }
        return target(chapter: chapter, mapping: mapping, progress: nil)
    }

    func resolveChapter(
        _ chapter: BookChapterMapping,
        mappings: [BookProgressTrackMapping],
        progress: EntityProgressCapability?
    ) -> BookCombinedResumeTarget? {
        guard let trackID = chapter.audioTrack?.id,
            let mapping = mappings.first(where: { $0.trackID == trackID })
        else { return nil }
        let matchingProgress = progress.flatMap {
            BookProgressMappingResolver().mapping(for: $0, in: [mapping]) == nil ? nil : $0
        }
        return target(chapter: chapter, mapping: mapping, progress: matchingProgress)
    }

    func resolveAudioResume(
        chapters: [BookChapterMapping],
        mappings: [BookProgressTrackMapping],
        progress: EntityProgressCapability?
    ) -> AudiobookResumePoint? {
        BookProgressMappingResolver().audioResume(
            tracks: chapters.compactMap(\.audioTrack),
            mappings: mappings,
            progress: progress
        )
    }

    private func target(
        chapter: BookChapterMapping,
        mapping: BookProgressTrackMapping,
        progress: EntityProgressCapability?
    ) -> BookCombinedResumeTarget? {
        guard let track = chapter.audioTrack,
            let duration = track.duration,
            duration.isFinite,
            duration > 0,
            let readTarget = chapter.readTarget
        else { return nil }

        let fraction = progress.map {
            BookProgressMappingResolver().fraction(for: $0, mapping: mapping)
        } ?? 0
        let readingTarget: BookCombinedReadingTarget
        switch readTarget {
        case .epub(let location):
            if let savedLocation = progress?.location,
                EPUBProgressLocation(serialized: savedLocation) != nil
            {
                readingTarget = .savedLocation(savedLocation)
            } else {
                readingTarget = .chapter(location: location, progression: fraction)
            }
        case .entityChapter(let chapterID):
            readingTarget = progress == nil
                ? .entityChapter(id: chapterID)
                : .savedLocation(nil)
        }

        let estimatedOffset = fraction * duration
        return BookCombinedResumeTarget(
            readingTarget: readingTarget,
            audioTrackID: track.id,
            audioStartSeconds: estimatedOffset <= audioRunwaySeconds
                ? 0
                : estimatedOffset - audioRunwaySeconds
        )
    }

    private func bounded(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(max(0, value), 1)
    }
}
