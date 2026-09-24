import Foundation

/// Aligns an older server's shared Book cursor with the audiobook on the client, for servers
/// before 3.8. Servers from 3.8 return resume, switch, and combined targets themselves.
struct LegacyBookCombinedResumeResolver: Sendable {
    private let audioRunwaySeconds = 5.0

    func resolveReadingTarget(
        chapters: [BookChapterMapping],
        trackID: UUID,
        trackOffsetSeconds: Double
    ) -> BookReaderLocationTarget? {
        guard let chapter = chapters.last(where: {
            guard $0.audioTrack?.id == trackID,
                let duration = $0.audioTrack?.duration
            else { return false }
            return trackOffsetSeconds >= ($0.audioStartSeconds ?? 0)
                && trackOffsetSeconds < ($0.audioEndSeconds ?? duration)
        }),
            case .epub(let location) = chapter.readTarget,
            let duration = chapter.audioEndSeconds ?? chapter.audioTrack?.duration,
            duration.isFinite,
            duration > (chapter.audioStartSeconds ?? 0)
        else { return nil }
        return BookReaderLocationTarget(
            location: location,
            progression: bounded((trackOffsetSeconds - (chapter.audioStartSeconds ?? 0))
                / (duration - (chapter.audioStartSeconds ?? 0)))
        )
    }

    func resolveContinuation(
        chapters: [BookChapterMapping],
        mappings: [PlaybackProgressMapping],
        progress: EntityProgressCapability?
    ) -> LegacyBookCombinedResumeTarget? {
        if let progress,
            progress.completedAt == nil
                || (progress.updatedAt ?? .distantPast) > (progress.completedAt ?? .distantFuture)
        {
            guard let mapping = LegacyBookProgressMappingResolver().mapping(for: progress, in: mappings),
                let chapter = LegacyBookProgressMappingResolver().chapter(for: mapping, in: chapters)
            else {
                // The readable cursor is authoritative when no audio part maps to it.
                return nil
            }
            return target(chapter: chapter, mapping: mapping, progress: progress)
        }

        guard let mapping = mappings.first,
            let chapter = LegacyBookProgressMappingResolver().chapter(for: mapping, in: chapters)
        else { return nil }
        return target(chapter: chapter, mapping: mapping, progress: nil)
    }

    /// Resumes the shared cursor, including reading after work completion.
    func resolveLatestContinuation(
        chapters: [BookChapterMapping],
        mappings: [PlaybackProgressMapping],
        progress: EntityProgressCapability?
    ) -> LegacyBookCombinedResumeTarget? {
        resolveContinuation(
            chapters: chapters,
            mappings: mappings,
            progress: progress?.readingPosition
        )
    }

    func resolveChapter(
        _ chapter: BookChapterMapping,
        mappings: [PlaybackProgressMapping],
        progress: EntityProgressCapability?
    ) -> LegacyBookCombinedResumeTarget? {
        guard let trackID = chapter.audioTrack?.id,
            let mapping = mappings.first(where: {
                $0.itemID == trackID
                    && $0.sourceStartSeconds == chapter.audioStartSeconds
                    && $0.sourceEndSeconds == chapter.audioEndSeconds
            })
        else { return nil }
        let matchingProgress = progress.flatMap {
            LegacyBookProgressMappingResolver().mapping(for: $0, in: [mapping]) == nil ? nil : $0
        }
        return target(chapter: chapter, mapping: mapping, progress: matchingProgress)
    }

    func resolveAudioResume(
        chapters: [BookChapterMapping],
        mappings: [PlaybackProgressMapping],
        progress: EntityProgressCapability?
    ) -> AudiobookResumePoint? {
        LegacyBookProgressMappingResolver().audioResume(
            tracks: chapters.compactMap(\.audioTrack),
            mappings: mappings,
            progress: progress
        )
    }

    private func target(
        chapter: BookChapterMapping,
        mapping: PlaybackProgressMapping,
        progress: EntityProgressCapability?
    ) -> LegacyBookCombinedResumeTarget? {
        guard let track = chapter.audioTrack,
            let duration = track.duration,
            duration.isFinite,
            duration > 0,
            let readTarget = chapter.readTarget
        else { return nil }

        let fraction = progress.map {
            LegacyBookProgressMappingResolver().fraction(for: $0, mapping: mapping)
        } ?? 0
        let readingTarget: LegacyBookCombinedReadingTarget
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

        let estimatedOffset = mapping.sourceOffset(for: fraction, duration: duration)
        let sourceStart = mapping.sourceStartSeconds ?? 0
        return LegacyBookCombinedResumeTarget(
            readingTarget: readingTarget,
            audioTrackID: track.id,
            audioStartSeconds: max(sourceStart, estimatedOffset - audioRunwaySeconds)
        )
    }

    private func bounded(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(max(0, value), 1)
    }
}
