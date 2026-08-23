import Foundation

/// Resolves the server's compact Book contents projection into native reading targets.
struct BookContentsService: Sendable {
    private let loader: any BookContentsLoading

    init(loader: any BookContentsLoading) {
        self.loader = loader
    }

    func load(book: EntityDetail) async throws -> BookChapterContents {
        guard BookChapterContentsLoadPolicy.canLoad(book) else {
            return BookChapterContents(chapters: [], currentChapterID: nil)
        }

        let entries = try await loader.loadBookContents(bookID: book.id)
        let chapters = entries.compactMap { chapter(from: $0, format: book.bookFormat) }
        let progress: EntityProgressCapability? = book.capability()
        return BookChapterContents(
            chapters: chapters,
            currentChapterID: currentChapterID(progress: progress, chapters: chapters),
            progressRanges: chapters.compactMap(progressRange)
        )
    }

    private func chapter(
        from entry: BookContentsEntry,
        format: BookFormat?
    ) -> ReadableBookChapter? {
        guard let target = readTarget(for: entry, format: format) else { return nil }
        return ReadableBookChapter(
            id: entry.id,
            title: entry.title,
            order: entry.order,
            depth: entry.depth,
            target: target,
            startFraction: entry.startFraction,
            endFraction: entry.endFraction,
            pageCount: entry.pageCount
        )
    }

    private func readTarget(
        for entry: BookContentsEntry,
        format: BookFormat?
    ) -> BookChapterReadTarget? {
        if format == .epub {
            return .epub(location: entry.location)
        }
        guard let chapterID = UUID(uuidString: entry.location) else { return nil }
        return .entityChapter(id: chapterID)
    }

    private func currentChapterID(
        progress: EntityProgressCapability?,
        chapters: [ReadableBookChapter]
    ) -> String? {
        if let entityID = progress?.currentEntityID,
            let chapter = chapters.first(where: { $0.target == .entityChapter(id: entityID) })
        {
            return chapter.id
        }
        return currentEPUBChapterID(
            progressLocation: progress?.completedAt == nil ? progress?.location : nil,
            chapters: chapters
        ) ?? currentFractionChapterID(progress: progress, chapters: chapters)
    }

    private func currentEPUBChapterID(
        progressLocation: String?,
        chapters: [ReadableBookChapter]
    ) -> String? {
        guard let href = href(from: progressLocation) else { return nil }
        let locations = chapters.compactMap { chapter -> String? in
            guard case .epub(let location) = chapter.target else { return nil }
            return location
        }
        guard
            let matched = EPUBResourceLocationMatcher().bestMatch(
                for: href,
                candidates: locations
            )
        else { return nil }
        return chapters.last { $0.target == .epub(location: matched) }?.id
    }

    private func currentFractionChapterID(
        progress: EntityProgressCapability?,
        chapters: [ReadableBookChapter]
    ) -> String? {
        guard let progress, progress.completedAt == nil, progress.total > 0 else { return nil }
        let fraction = min(max(0, Double(progress.index) / Double(progress.total)), 1)
        return chapters.last {
            guard let start = $0.startFraction, let end = $0.endFraction else { return false }
            return fraction >= start && fraction <= end
        }?.id
    }

    private func progressRange(_ chapter: ReadableBookChapter) -> EPUBReadingProgressRange? {
        guard case .epub(let location) = chapter.target,
            let startFraction = chapter.startFraction,
            let endFraction = chapter.endFraction
        else { return nil }
        return EPUBReadingProgressRange(
            location: location,
            startFraction: startFraction,
            endFraction: endFraction
        )
    }

    private func href(from progressLocation: String?) -> String? {
        if let progressLocation,
            let location = EPUBProgressLocation(serialized: progressLocation)
        {
            return location.href
        }
        guard let progressLocation,
            let data = progressLocation.data(using: .utf8),
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let href = object["href"] as? String
        else {
            guard let progressLocation, !progressLocation.hasPrefix("epubcfi(") else { return nil }
            return progressLocation
        }
        return href
    }
}
