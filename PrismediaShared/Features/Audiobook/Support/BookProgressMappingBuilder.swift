import Foundation

struct BookProgressMappingBuilder: Sendable {
    private let epubProgressTotal = 10_000

    func build(
        bookID: UUID,
        chapters: [BookChapterMapping],
        readerMode: ReaderMode?,
        hasReadableRendition: Bool
    ) -> [BookProgressTrackMapping] {
        guard hasReadableRendition else {
            return audioOnlyMappings(bookID: bookID, chapters: chapters)
        }

        return chapters.compactMap { chapter in
            guard let track = chapter.audioTrack, let readTarget = chapter.readTarget else {
                return nil
            }

            switch readTarget {
            case .epub:
                guard let start = chapter.readStartFraction,
                    let end = chapter.readEndFraction,
                    start.isFinite,
                    end.isFinite,
                    end > start
                else { return nil }
                return BookProgressTrackMapping(
                    trackID: track.id,
                    currentEntityID: bookID,
                    unit: .cfi,
                    startIndex: Int((bounded(start) * Double(epubProgressTotal)).rounded()),
                    endIndex: Int((bounded(end) * Double(epubProgressTotal)).rounded()),
                    total: epubProgressTotal,
                    mode: readerMode
                )
            case .entityChapter(let chapterID):
                let pageCount = max(0, chapter.readPageCount ?? 0)
                guard pageCount > 0 else { return nil }
                return BookProgressTrackMapping(
                    trackID: track.id,
                    currentEntityID: chapterID,
                    unit: .page,
                    startIndex: 0,
                    endIndex: pageCount - 1,
                    total: pageCount,
                    mode: readerMode
                )
            }
        }
    }

    private func audioOnlyMappings(
        bookID: UUID,
        chapters: [BookChapterMapping]
    ) -> [BookProgressTrackMapping] {
        let durations = chapters.map { chapter in
            guard let duration = chapter.audioTrack?.duration, duration.isFinite else { return 0 }
            return max(0, Int(duration.rounded(.up)))
        }
        let total = durations.reduce(0, +)
        guard total > 0 else { return [] }

        var startIndex = 0
        return chapters.enumerated().compactMap { index, chapter in
            let duration = durations[index]
            guard let track = chapter.audioTrack, duration > 0 else { return nil }
            defer { startIndex += duration }
            return BookProgressTrackMapping(
                trackID: track.id,
                currentEntityID: bookID,
                unit: .second,
                startIndex: startIndex,
                endIndex: startIndex + duration,
                total: total,
                mode: nil
            )
        }
    }

    private func bounded(_ value: Double) -> Double {
        min(max(0, value), 1)
    }
}
