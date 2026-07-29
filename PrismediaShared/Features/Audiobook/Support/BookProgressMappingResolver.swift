import Foundation

struct BookProgressMappingResolver: Sendable {
    private let audioRunwaySeconds = 5.0

    func progressRequest(
        mapping: BookProgressTrackMapping,
        offsetSeconds: Double,
        durationSeconds: Double,
        activitySeconds: Double?,
        completed: Bool
    ) -> EntityProgressUpdateRequest {
        let duration = durationSeconds.isFinite ? max(0, durationSeconds) : 0
        let offset = offsetSeconds.isFinite ? max(0, offsetSeconds) : 0
        let fraction = duration > 0 ? bounded(offset / duration) : 0
        let index: Int
        if mapping.unit == .page {
            index = max(
                mapping.startIndex,
                min(mapping.endIndex, Int(ceil(fraction * Double(mapping.total))) - 1)
            )
        } else {
            index = max(
                mapping.startIndex,
                min(
                    mapping.endIndex,
                    Int(
                        (Double(mapping.startIndex)
                            + fraction * Double(mapping.endIndex - mapping.startIndex))
                            .rounded()
                    )
                )
            )
        }

        return EntityProgressUpdateRequest(
            currentEntityID: mapping.currentEntityID,
            unit: mapping.unit,
            index: index,
            total: mapping.total,
            mode: mapping.mode,
            completed: completed ? true : nil,
            location: nil,
            activitySeconds: activitySeconds,
            activityKind: .listening
        )
    }

    func mapping(
        for progress: EntityProgressCapability,
        in mappings: [BookProgressTrackMapping]
    ) -> BookProgressTrackMapping? {
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
        mappings: [BookProgressTrackMapping],
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
            let chapter = chapters.first(where: { $0.audioTrack?.id == mapping.trackID })
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
        mappings: [BookProgressTrackMapping],
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
            let candidateOrder = mappings.firstIndex(where: { $0.trackID == resume.trackID }),
            let duration = tracks.first(where: { $0.id == resume.trackID })?.duration,
            duration.isFinite,
            duration > 0
        else { return nil }

        let candidateMapping = mappings[candidateOrder]
        let candidate = progressRequest(
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
        return candidate.index > progress.index ? candidate : nil
    }

    func audioResume(
        tracks: [MusicTrack],
        mappings: [BookProgressTrackMapping],
        progress: EntityProgressCapability?
    ) -> AudiobookResumePoint? {
        guard let progress,
            progress.completedAt == nil,
            let mapping = mapping(for: progress, in: mappings),
            let track = tracks.first(where: { $0.id == mapping.trackID })
        else { return nil }

        let span = mapping.endIndex - mapping.startIndex
        let fraction = span > 0
            ? bounded(Double(progress.index - mapping.startIndex) / Double(span))
            : 0
        let duration = track.duration.flatMap { $0.isFinite ? max(0, $0) : nil } ?? 0
        return AudiobookResumePoint(
            trackID: track.id,
            trackOffsetSeconds: runwayStart(fraction * duration)
        )
    }

    func fraction(
        for progress: EntityProgressCapability,
        mapping: BookProgressTrackMapping
    ) -> Double {
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
