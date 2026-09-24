import Foundation

struct BookCombinedResumeResolver: Sendable {
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
    ) -> BookCombinedResumeTarget? {
        if let progress,
            progress.completedAt == nil
                || (progress.updatedAt ?? .distantPast) > (progress.completedAt ?? .distantFuture)
        {
            guard let mapping = BookProgressMappingResolver().mapping(for: progress, in: mappings),
                let chapter = BookProgressMappingResolver().chapter(for: mapping, in: chapters)
            else {
                // The readable cursor is authoritative when no audio part maps to it.
                return nil
            }
            return target(chapter: chapter, mapping: mapping, progress: progress)
        }

        guard let mapping = mappings.first,
            let chapter = BookProgressMappingResolver().chapter(for: mapping, in: chapters)
        else { return nil }
        return target(chapter: chapter, mapping: mapping, progress: nil)
    }

    /// Resumes the most recently used rendition, including activity after work completion.
    func resolveLatestContinuation(
        chapters: [BookChapterMapping],
        mappings: [PlaybackProgressMapping],
        progress: EntityProgressCapability?
    ) -> BookCombinedResumeTarget? {
        guard let progress else {
            return resolveContinuation(chapters: chapters, mappings: mappings, progress: nil)
        }

        if let listening = progress.listening,
            listening.updatedAt > (progress.reading?.updatedAt ?? .distantPast),
            listening.updatedAt > (progress.completedAt ?? .distantPast)
        {
            return listeningTarget(
                chapters: chapters,
                mappings: mappings,
                trackID: listening.trackEntityID,
                offset: listening.offsetSeconds
            )
        }

        return resolveContinuation(
            chapters: chapters,
            mappings: mappings,
            progress: progress.readablePosition
        )
    }

    func resolveChapter(
        _ chapter: BookChapterMapping,
        mappings: [PlaybackProgressMapping],
        progress: EntityProgressCapability?
    ) -> BookCombinedResumeTarget? {
        guard let trackID = chapter.audioTrack?.id,
            let mapping = mappings.first(where: {
                $0.itemID == trackID
                    && $0.sourceStartSeconds == chapter.audioStartSeconds
                    && $0.sourceEndSeconds == chapter.audioEndSeconds
            })
        else { return nil }
        let matchingProgress = progress.flatMap {
            BookProgressMappingResolver().mapping(for: $0, in: [mapping]) == nil ? nil : $0
        }
        return target(chapter: chapter, mapping: mapping, progress: matchingProgress)
    }

    func resolveAudioResume(
        chapters: [BookChapterMapping],
        mappings: [PlaybackProgressMapping],
        progress: EntityProgressCapability?
    ) -> AudiobookResumePoint? {
        if let exact = exactAudioResume(chapters: chapters, progress: progress) {
            return exact
        }
        return BookProgressMappingResolver().audioResume(
            tracks: chapters.compactMap(\.audioTrack),
            mappings: mappings,
            progress: progress
        )
    }

    func exactAudioResume(
        chapters: [BookChapterMapping],
        progress: EntityProgressCapability?
    ) -> AudiobookResumePoint? {
        guard let listening = progress?.listening,
            listening.updatedAt > (progress?.completedAt ?? .distantPast),
            listening.offsetSeconds.isFinite,
            listening.offsetSeconds >= 0,
            chapters.contains(where: { $0.audioTrack?.id == listening.trackEntityID })
        else { return nil }
        return AudiobookResumePoint(
            trackID: listening.trackEntityID,
            trackOffsetSeconds: listening.offsetSeconds
        )
    }

    private func listeningTarget(
        chapters: [BookChapterMapping],
        mappings: [PlaybackProgressMapping],
        trackID: UUID,
        offset: Double
    ) -> BookCombinedResumeTarget? {
        guard offset.isFinite, offset >= 0,
            let chapter = chapters.last(where: { chapter in
                guard chapter.audioTrack?.id == trackID,
                    let duration = chapter.audioTrack?.duration
                else { return false }
                return offset >= (chapter.audioStartSeconds ?? 0)
                    && (offset < (chapter.audioEndSeconds ?? duration)
                        || (offset >= duration && (chapter.audioEndSeconds ?? duration) >= duration))
            }),
            let readTarget = chapter.readTarget,
            mappings.contains(where: {
                $0.itemID == trackID
                    && $0.sourceStartSeconds == chapter.audioStartSeconds
                    && $0.sourceEndSeconds == chapter.audioEndSeconds
            }),
            let duration = chapter.audioEndSeconds ?? chapter.audioTrack?.duration,
            duration.isFinite,
            duration > (chapter.audioStartSeconds ?? 0)
        else { return nil }

        let start = chapter.audioStartSeconds ?? 0
        let fraction = bounded((offset - start) / (duration - start))
        let readingTarget: BookCombinedReadingTarget
        switch readTarget {
        case .epub(let location):
            readingTarget = .chapter(location: location, progression: fraction)
        case .entityChapter(let chapterID):
            readingTarget = .entityChapter(id: chapterID)
        }
        return BookCombinedResumeTarget(
            readingTarget: readingTarget,
            audioTrackID: trackID,
            audioStartSeconds: max(start, offset - audioRunwaySeconds)
        )
    }

    private func target(
        chapter: BookChapterMapping,
        mapping: PlaybackProgressMapping,
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

        let estimatedOffset = mapping.sourceOffset(for: fraction, duration: duration)
        let sourceStart = mapping.sourceStartSeconds ?? 0
        return BookCombinedResumeTarget(
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
