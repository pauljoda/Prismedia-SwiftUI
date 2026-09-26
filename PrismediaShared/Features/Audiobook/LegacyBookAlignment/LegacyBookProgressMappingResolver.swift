import Foundation

/// Resolves an older server's shared Book cursor against client-side progress mappings (before
/// 3.8), including the one-time promotion of legacy absolute audiobook resume seconds.
struct LegacyBookProgressMappingResolver: Sendable {
    private let audioRunwaySeconds = 5.0

    func mapping(
        for progress: EntityProgressCapability,
        in mappings: [PlaybackProgressMapping]
    ) -> PlaybackProgressMapping? {
        let candidates = mappings.filter {
            $0.currentEntityID == progress.currentEntityID && $0.unit == progress.unit
        }
        return candidates.last {
            progress.index >= $0.startIndex && progress.index <= $0.endIndex
        }
    }

    func currentChapterID(
        bookID: UUID,
        chapters: [BookChapterMapping],
        mappings: [PlaybackProgressMapping],
        progress: EntityProgressCapability?
    ) -> String? {
        guard let progress, progress.completedAt == nil else { return nil }

        if progress.currentEntityID == bookID,
            progress.unit == .cfi,
            let location = progress.location.flatMap(EPUBProgressLocation.init(serialized:)),
            let chapterID = epubChapterID(for: location.href, in: chapters)
        {
            return chapterID
        }

        if let mapping = mapping(for: progress, in: mappings),
            let chapter = chapter(for: mapping, in: chapters)
        {
            return chapter.id
        }

        if progress.unit == .page,
            let currentEntityID = progress.currentEntityID
        {
            return chapters.first { chapter in
                guard case .some(.entityChapter(let chapterID)) = chapter.readTarget else {
                    return false
                }
                return chapterID == currentEntityID
            }?.id
        }

        guard progress.currentEntityID == bookID,
            progress.unit == .cfi,
            progress.total > 0
        else { return nil }
        let fraction = bounded(Double(progress.index) / Double(progress.total))
        return chapters.last { chapter in
            guard let start = chapter.readStartFraction,
                let end = chapter.readEndFraction
            else { return false }
            return fraction >= start && fraction <= end
        }?.id
    }

    func legacyProgressPromotionRequest(
        tracks: [MusicTrack],
        mappings: [PlaybackProgressMapping],
        legacyResumeSeconds: Double,
        progress: EntityProgressCapability?
    ) -> EntityProgressUpdateRequest? {
        guard legacyResumeSeconds.isFinite,
            legacyResumeSeconds > 0,
            progress?.completedAt == nil,
            let firstMapping = mappings.first,
            let resume = AudiobookPlaybackProjection(
                bookID: firstMapping.currentEntityID,
                title: "",
                tracks: tracks
            ).resumePoint(at: legacyResumeSeconds),
            let duration = tracks.first(where: { $0.id == resume.trackID })?.duration,
            duration.isFinite,
            duration > 0,
            let candidateOrder = mappings.lastIndex(where: {
                $0.itemID == resume.trackID
                    && $0.containsSourceOffset(resume.trackOffsetSeconds, duration: duration)
            })
        else { return nil }

        let candidateMapping = mappings[candidateOrder]
        let candidate = LegacyAudioProgressMappingResolver().progressRequest(
            mapping: candidateMapping,
            offsetSeconds: resume.trackOffsetSeconds,
            durationSeconds: duration,
            activitySeconds: nil,
            completed: false
        )

        guard let progress else { return candidate }
        guard let currentMapping = mapping(for: progress, in: mappings),
            let currentOrder = mappings.firstIndex(of: currentMapping)
        else {
            // An unresolvable readable cursor remains authoritative.
            return nil
        }

        if candidateOrder != currentOrder {
            return candidateOrder > currentOrder ? candidate : nil
        }
        return (candidate.index ?? 0) > progress.index ? candidate : nil
    }

    func audioResume(
        tracks: [MusicTrack],
        mappings: [PlaybackProgressMapping],
        progress: EntityProgressCapability?
    ) -> AudiobookResumePoint? {
        guard let progress,
            progress.completedAt == nil,
            let mapping = mapping(for: progress, in: mappings),
            let track = tracks.first(where: { $0.id == mapping.itemID })
        else { return nil }

        let fraction = fraction(for: progress, mapping: mapping)
        let duration = track.duration.flatMap { $0.isFinite ? max(0, $0) : nil } ?? 0
        let estimatedOffset = mapping.sourceOffset(for: fraction, duration: duration)
        let start = mapping.sourceStartSeconds ?? 0
        return AudiobookResumePoint(
            trackID: track.id,
            trackOffsetSeconds: max(start, runwayStart(estimatedOffset))
        )
    }

    func chapter(
        for mapping: PlaybackProgressMapping,
        in chapters: [BookChapterMapping]
    ) -> BookChapterMapping? {
        chapters.first {
            $0.audioTrack?.id == mapping.itemID
                && $0.audioStartSeconds == mapping.sourceStartSeconds
                && $0.audioEndSeconds == mapping.sourceEndSeconds
        }
    }

    func fraction(
        for progress: EntityProgressCapability,
        mapping: PlaybackProgressMapping
    ) -> Double {
        if mapping.unit == .cfi,
            let readerLocation = mapping.resourceLocation,
            let savedLocation = progress.location.flatMap(EPUBProgressLocation.init(serialized:)),
            EPUBResourceLocationMatcher().bestMatch(
                for: savedLocation.href,
                candidates: [readerLocation]
            ) != nil
        {
            return savedLocation.resourceProgression
        }

        let span = mapping.endIndex - mapping.startIndex
        guard span > 0 else { return 0 }
        return bounded(Double(progress.index - mapping.startIndex) / Double(span))
    }

    private func runwayStart(_ seconds: Double) -> Double {
        seconds <= audioRunwaySeconds ? 0 : seconds - audioRunwaySeconds
    }

    private func epubChapterID(
        for href: String,
        in chapters: [BookChapterMapping]
    ) -> String? {
        let locations = chapters.compactMap { chapter -> String? in
            guard case .some(.epub(let location)) = chapter.readTarget else { return nil }
            return location
        }
        guard let match = EPUBResourceLocationMatcher().bestMatch(
            for: href,
            candidates: locations
        ) else { return nil }
        return chapters.first { chapter in
            guard case .some(.epub(let location)) = chapter.readTarget else { return false }
            return location == match
        }?.id
    }

    private func bounded(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(max(0, value), 1)
    }
}
