import Foundation

public struct DocumentReaderProgressMapper: Sendable {
    public static func epubBookProgression(
        chapterIndex: Int,
        chapterCount: Int,
        chapterProgression: Double
    ) -> Double {
        let boundedCount = max(1, chapterCount)
        let boundedIndex = max(0, min(chapterIndex, boundedCount - 1))
        let boundedChapterProgression = min(max(chapterProgression, 0), 1)
        return (Double(boundedIndex) + boundedChapterProgression) / Double(boundedCount)
    }

    public static func epubBookProgression(
        chapterIndex: Int,
        chapterContentSizes: [Int],
        chapterProgression: Double
    ) -> Double {
        let sizes = chapterContentSizes.map { max(0, $0) }
        let total = sizes.reduce(0, +)
        guard total > 0, sizes.indices.contains(chapterIndex) else {
            return epubBookProgression(
                chapterIndex: chapterIndex,
                chapterCount: sizes.count,
                chapterProgression: chapterProgression
            )
        }
        let elapsed = sizes.prefix(chapterIndex).reduce(0, +)
        let local = Double(sizes[chapterIndex]) * min(max(chapterProgression, 0), 1)
        return min(max(0, (Double(elapsed) + local) / Double(total)), 1)
    }

    public static func epubBookProgression(
        resourceLocation: String,
        ranges: [EPUBReadingProgressRange],
        resourceProgression: Double
    ) -> Double? {
        guard let matchedLocation = EPUBResourceLocationMatcher().bestMatch(
            for: resourceLocation,
            candidates: ranges.map(\.location)
        ),
            let range = ranges.last(where: { $0.location == matchedLocation }),
            range.endFraction > range.startFraction
        else { return nil }
        let localProgression = min(max(resourceProgression, 0), 1)
        return range.startFraction
            + localProgression * (range.endFraction - range.startFraction)
    }

    public static func epubRequest(
        bookID: UUID,
        progression: Double,
        mode: ReaderMode,
        location: String?,
        closing: Bool
    ) -> EntityProgressUpdateRequest {
        let boundedProgression = min(max(progression, 0), 1)
        let index = Int((boundedProgression * 10_000).rounded())
        return EntityProgressUpdateRequest(
            currentEntityID: bookID,
            unit: .cfi,
            index: index,
            total: 10_000,
            mode: mode == .scrolled ? .scrolled : .paged,
            completed: closing && boundedProgression >= 0.995 ? true : nil,
            reset: false,
            location: location
        )
    }

    public static func initialIndex(
        progress: EntityProgressCapability?,
        locations: [String]
    ) -> Int {
        guard let progress, progress.completedAt == nil, !locations.isEmpty else { return 0 }
        if let savedLocation = progress.location,
            let location = epubBaseLocation(savedLocation),
            let locationIndex = locations.firstIndex(of: location)
        {
            return locationIndex
        }
        return max(0, min(progress.index, locations.count - 1))
    }

    public static func epubLocation(chapterLocation: String, progress: Double) -> String {
        let boundedProgress = min(max(progress, 0), 1)
        return "\(epubBaseLocation(chapterLocation) ?? chapterLocation)#prismedia-progress=\(boundedProgress)"
    }

    public static func epubProgress(from location: String?) -> Double? {
        guard
            let location,
            let marker = location.range(of: "#prismedia-progress="),
            let value = Double(location[marker.upperBound...])
        else { return nil }
        return min(max(value, 0), 1)
    }

    public static func epubBaseLocation(_ location: String?) -> String? {
        guard let location else { return nil }
        guard let marker = location.range(of: "#prismedia-progress=") else { return location }
        return String(location[..<marker.lowerBound])
    }

    public static func sharedEPUBLocation(_ location: String?) -> String? {
        guard let location,
            location.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().hasPrefix("epubcfi(")
        else { return nil }
        return location
    }

    public static func request(
        bookID: UUID,
        index: Int,
        total: Int,
        unit: ProgressUnit,
        mode: ReaderMode,
        location: String?,
        completesAtEnd: Bool = true,
        reset: Bool = false
    ) -> EntityProgressUpdateRequest {
        let boundedTotal = max(1, total)
        let boundedIndex = max(0, min(index, boundedTotal - 1))
        return EntityProgressUpdateRequest(
            currentEntityID: bookID,
            unit: unit,
            index: boundedIndex,
            total: boundedTotal,
            mode: mode,
            completed: completesAtEnd && boundedIndex == boundedTotal - 1 ? true : nil,
            reset: reset,
            location: location
        )
    }
}
