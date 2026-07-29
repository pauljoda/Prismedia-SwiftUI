import Foundation

struct EPUBStoredProgressPromotionResolver: Sendable {
    func request(
        bookID: UUID,
        storedLocation: String?,
        ranges: [EPUBReadingProgressRange],
        mode: ReaderMode,
        progress: EntityProgressCapability?
    ) -> EntityProgressUpdateRequest? {
        guard progress?.completedAt == nil,
            let storedLocation,
            let stored = EPUBProgressLocation(serialized: storedLocation),
            let candidateProgression = DocumentReaderProgressMapper.epubBookProgression(
                resourceLocation: stored.href,
                ranges: ranges,
                resourceProgression: stored.resourceProgression
            )
        else { return nil }

        let candidate = DocumentReaderProgressMapper.epubRequest(
            bookID: bookID,
            progression: candidateProgression,
            mode: mode,
            location: storedLocation,
            closing: false
        )
        guard let progress else { return candidate }

        let currentLocation = progress.location.flatMap(EPUBProgressLocation.init(serialized:))
        let candidateRange = rangeIndex(for: stored.href, ranges: ranges)
        let currentRange = currentLocation
            .flatMap { rangeIndex(for: $0.href, ranges: ranges) }
            ?? rangeIndex(for: progress, bookID: bookID, ranges: ranges)

        if let candidateRange, let currentRange, candidateRange != currentRange {
            return candidateRange > currentRange ? candidate : nil
        }
        if let currentLocation,
            EPUBResourceLocationMatcher().bestMatch(
                for: stored.href,
                candidates: [currentLocation.href]
            ) != nil
        {
            return stored.resourceProgression > currentLocation.resourceProgression
                ? candidate
                : nil
        }
        return candidate.index > progress.index ? candidate : nil
    }

    private func rangeIndex(
        for location: String,
        ranges: [EPUBReadingProgressRange]
    ) -> Int? {
        guard let match = EPUBResourceLocationMatcher().bestMatch(
            for: location,
            candidates: ranges.map(\.location)
        ) else { return nil }
        return ranges.lastIndex { $0.location == match }
    }

    private func rangeIndex(
        for progress: EntityProgressCapability,
        bookID: UUID,
        ranges: [EPUBReadingProgressRange]
    ) -> Int? {
        guard progress.currentEntityID == bookID,
            progress.unit == .cfi,
            progress.total > 0
        else { return nil }
        let fraction = min(max(0, Double(progress.index) / Double(progress.total)), 1)
        return ranges.lastIndex {
            fraction >= $0.startFraction && fraction <= $0.endFraction
        }
    }
}
