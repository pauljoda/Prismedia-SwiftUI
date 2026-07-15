import Foundation

struct BookCombinedResumeResolver: Sendable {
    private let audioRunwaySeconds = 5.0

    func resolveContinuation(
        chapters: [BookChapterMapping],
        reading: BookReadingCheckpoint?,
        listening: BookListeningCheckpoint?
    ) -> BookCombinedResumeTarget? {
        let available = chapters.filter { $0.readLocation != nil && $0.audioTrack != nil }
        guard !available.isEmpty else { return nil }

        let readingPosition = reading.flatMap { checkpoint in
            available.firstIndex { chapter in
                chapter.readLocation.map {
                    EPUBResourceLocationMatcher().bestMatch(
                        for: checkpoint.chapterLocation,
                        candidates: [$0]
                    ) != nil
                } ?? false
            }.map { (index: $0, fraction: checkpoint.chapterProgression) }
        }
        let listeningPosition = listening.flatMap { checkpoint in
            available.firstIndex { $0.audioTrack?.id == checkpoint.trackID }.flatMap { index in
                localAudioProgress(checkpoint, chapter: available[index]).map {
                    (index: index, fraction: $0)
                }
            }
        }

        switch preferredPosition(reading: readingPosition, listening: listeningPosition) {
        case .reading(let index, let fraction):
            return targetFromReading(chapter: available[index], fraction: fraction)
        case .listening(let index, let fraction):
            return targetFromListening(
                chapter: available[index],
                fraction: fraction,
                offset: listening?.trackOffsetSeconds ?? 0
            )
        case nil:
            guard reading == nil, listening == nil else { return nil }
            return resolveChapter(available[0], reading: nil, listening: nil)
        }
    }

    func resolveChapter(
        _ chapter: BookChapterMapping,
        reading: BookReadingCheckpoint?,
        listening: BookListeningCheckpoint?
    ) -> BookCombinedResumeTarget? {
        guard chapter.readLocation != nil, chapter.audioTrack != nil else { return nil }

        let readingFraction = reading.flatMap { checkpoint -> Double? in
            guard let location = chapter.readLocation,
                  EPUBResourceLocationMatcher().bestMatch(
                    for: checkpoint.chapterLocation,
                    candidates: [location]
                  ) != nil else { return nil }
            return checkpoint.chapterProgression
        }
        let listeningFraction = listening.flatMap { checkpoint -> Double? in
            guard checkpoint.trackID == chapter.audioTrack?.id else { return nil }
            return localAudioProgress(checkpoint, chapter: chapter)
        }

        if let listeningFraction,
           listeningFraction > (readingFraction ?? -1) {
            return targetFromListening(
                chapter: chapter,
                fraction: listeningFraction,
                offset: listening?.trackOffsetSeconds ?? 0
            )
        }
        if let readingFraction {
            return targetFromReading(chapter: chapter, fraction: readingFraction)
        }
        return targetFromListening(chapter: chapter, fraction: 0, offset: 0)
    }

    private func preferredPosition(
        reading: (index: Int, fraction: Double)?,
        listening: (index: Int, fraction: Double)?
    ) -> BookCombinedPreferredPosition? {
        switch (reading, listening) {
        case let (.some(reading), .some(listening)):
            if reading.index != listening.index {
                return reading.index > listening.index
                    ? .reading(index: reading.index, fraction: reading.fraction)
                    : .listening(index: listening.index, fraction: listening.fraction)
            }
            return listening.fraction > reading.fraction
                ? .listening(index: listening.index, fraction: listening.fraction)
                : .reading(index: reading.index, fraction: reading.fraction)
        case let (.some(reading), nil):
            return .reading(index: reading.index, fraction: reading.fraction)
        case let (nil, .some(listening)):
            return .listening(index: listening.index, fraction: listening.fraction)
        case (nil, nil):
            return nil
        }
    }

    private func localAudioProgress(
        _ checkpoint: BookListeningCheckpoint,
        chapter: BookChapterMapping
    ) -> Double? {
        guard let duration = chapter.audioTrack?.duration,
              duration.isFinite,
              duration > 0 else { return nil }
        return min(max(0, checkpoint.trackOffsetSeconds / duration), 1)
    }

    private func targetFromReading(
        chapter: BookChapterMapping,
        fraction: Double
    ) -> BookCombinedResumeTarget? {
        guard let track = chapter.audioTrack,
              let duration = track.duration,
              duration.isFinite,
              duration > 0 else { return nil }
        let estimatedOffset = min(max(0, fraction), 1) * duration
        let audioStart = estimatedOffset <= audioRunwaySeconds
            ? 0
            : estimatedOffset - audioRunwaySeconds
        return BookCombinedResumeTarget(
            readingTarget: .savedLocation,
            audioTrackID: track.id,
            audioStartSeconds: audioStart
        )
    }

    private func targetFromListening(
        chapter: BookChapterMapping,
        fraction: Double,
        offset: Double
    ) -> BookCombinedResumeTarget? {
        guard let location = chapter.readLocation,
              let trackID = chapter.audioTrack?.id else { return nil }
        return BookCombinedResumeTarget(
            readingTarget: .chapter(
                location: location,
                progression: min(max(0, fraction), 1)
            ),
            audioTrackID: trackID,
            audioStartSeconds: offset < audioRunwaySeconds ? 0 : offset
        )
    }
}

private extension BookChapterMapping {
    var readLocation: String? {
        guard case .epub(let location) = readTarget else { return nil }
        return location
    }
}
