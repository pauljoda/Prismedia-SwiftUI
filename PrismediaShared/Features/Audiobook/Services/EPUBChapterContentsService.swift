import Foundation

struct EPUBChapterContentsService: Sendable {
    private let reader: any BookReaderServicing

    init(reader: any BookReaderServicing) {
        self.reader = reader
    }

    func load(book: EntityDetail, storedLocation: String? = nil) async throws -> EPUBChapterContents {
        guard BookChapterContentsLoadPolicy.canLoad(book) else {
            return EPUBChapterContents(chapters: [], currentChapterID: nil)
        }

        if book.bookFormat == .imageArchive {
            return try await loadImageChapters(book: book)
        }

        let data = try await reader.loadSourceData(id: book.id)
        let title = book.title
        let destination = cacheDirectory(bookID: book.id)
        let publication = try await Task.detached(priority: .userInitiated) {
            try EPUBPublicationLoader().load(
                data: data,
                fallbackTitle: title,
                destination: destination,
                extractsContent: false
            )
        }.value
        let chapters = readableChapters(in: publication)
        let progress: EntityProgressCapability? = book.capability()
        return EPUBChapterContents(
            chapters: chapters,
            currentChapterID: currentChapterID(
                progressLocation: progress?.completedAt == nil
                    ? (storedLocation ?? progress?.location)
                    : nil,
                chapters: chapters
            ) ?? currentChapterID(progress: progress, chapters: chapters)
        )
    }

    private func readableChapters(in publication: EPUBPublication) -> [ReadableBookChapter] {
        let tableOfContents = flattenedChapters(publication.tableOfContents)
        let ranges = chapterRanges(in: publication)
        guard tableOfContents.isEmpty else {
            return tableOfContents.enumerated().map { index, chapter in
                let chapterIndex = publication.chapters.firstIndex {
                    normalizedResource($0.location) == normalizedResource(chapter.id)
                }
                let nextChapterIndex = tableOfContents.dropFirst(index + 1).compactMap { next in
                    publication.chapters.firstIndex {
                        normalizedResource($0.location) == normalizedResource(next.id)
                    }
                }.first { candidate in
                    guard let chapterIndex else { return false }
                    return candidate > chapterIndex
                }
                let start = chapterIndex.flatMap { ranges.indices.contains($0) ? ranges[$0].start : nil }
                let endIndex = nextChapterIndex ?? publication.chapters.count
                let end = ranges.indices.contains(endIndex - 1) ? ranges[endIndex - 1].end : nil
                return ReadableBookChapter(
                    id: chapter.id,
                    title: chapter.title,
                    order: chapter.order,
                    depth: chapter.depth,
                    target: chapter.target,
                    startFraction: start,
                    endFraction: end
                )
            }
        }

        return publication.chapters.enumerated().map { index, chapter in
            ReadableBookChapter(
                id: chapter.location,
                title: fallbackTitle(for: chapter.location, index: index),
                order: index,
                depth: 0,
                target: .epub(location: chapter.location),
                startFraction: ranges.indices.contains(index) ? ranges[index].start : nil,
                endFraction: ranges.indices.contains(index) ? ranges[index].end : nil
            )
        }
    }

    private func chapterRanges(in publication: EPUBPublication) -> [(start: Double, end: Double)] {
        let sizes = publication.chapters.map { max(0, $0.contentSize) }
        let total = sizes.reduce(0, +)
        guard total > 0 else { return [] }
        var accumulated = 0
        return sizes.map { size in
            let start = Double(accumulated) / Double(total)
            accumulated += size
            return (start, Double(accumulated) / Double(total))
        }
    }

    private func loadImageChapters(book: EntityDetail) async throws -> EPUBChapterContents {
        var chapterThumbnails = orderedChildren(in: book, kind: .bookChapter)
        if chapterThumbnails.isEmpty {
            for volume in orderedChildren(in: book, kind: .bookVolume) {
                let detail = try await reader.loadEntity(id: volume.id)
                chapterThumbnails += orderedChildren(in: detail, kind: .bookChapter)
            }
        }

        var chapters: [ReadableBookChapter] = []
        for (index, chapter) in chapterThumbnails.enumerated() {
            let detail = try await reader.loadEntity(id: chapter.id)
            let pageCount = orderedChildren(in: detail, kind: .bookPage).count
            guard pageCount > 0 else { continue }
            chapters.append(
                ReadableBookChapter(
                    id: chapter.id.uuidString.lowercased(),
                    title: chapter.title,
                    order: index,
                    depth: 0,
                    target: .entityChapter(id: chapter.id),
                    pageCount: pageCount
                )
            )
        }

        let progress: EntityProgressCapability? = book.capability()
        return EPUBChapterContents(
            chapters: chapters,
            currentChapterID: progress?.completedAt == nil
                ? progress?.currentEntityID?.uuidString.lowercased()
                : nil
        )
    }

    private func orderedChildren(in detail: EntityDetail, kind: EntityKind) -> [EntityThumbnail] {
        let children = detail.childrenByKind.first { $0.kind == kind }?.entities ?? []
        return children.sorted {
            ($0.sortOrder ?? Int.max, $0.title, $0.id.uuidString)
                < ($1.sortOrder ?? Int.max, $1.title, $1.id.uuidString)
        }
    }

    private func fallbackTitle(for location: String, index: Int) -> String {
        let decoded = location.removingPercentEncoding ?? location
        let name = ((decoded as NSString).lastPathComponent as NSString).deletingPathExtension
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "Chapter \(index + 1)" : name
    }

    private func flattenedChapters(
        _ items: [EPUBTableOfContentsItem]
    ) -> [ReadableBookChapter] {
        var flattened: [(title: String, location: String, depth: Int)] = []

        func visit(_ items: [EPUBTableOfContentsItem], depth: Int) {
            for item in items {
                if let location = item.location?.trimmingCharacters(in: .whitespacesAndNewlines),
                    !location.isEmpty
                {
                    flattened.append((item.title, location, depth))
                }
                visit(item.children, depth: depth + 1)
            }
        }

        visit(items, depth: 0)
        var deepestByLocation: [String: Int] = [:]
        for (index, chapter) in flattened.enumerated() {
            let key = normalizedResource(chapter.location)
            guard let current = deepestByLocation[key] else {
                deepestByLocation[key] = index
                continue
            }
            if flattened[current].depth < chapter.depth {
                deepestByLocation[key] = index
            }
        }

        return flattened.enumerated().compactMap { index, chapter in
            let key = normalizedResource(chapter.location)
            guard deepestByLocation[key] == index else { return nil }
            return ReadableBookChapter(
                id: chapter.location,
                title: chapter.title,
                order: index,
                depth: chapter.depth,
                target: .epub(location: chapter.location)
            )
        }
    }

    func currentChapterID(
        progressLocation: String?,
        chapters: [ReadableBookChapter]
    ) -> String? {
        guard let href = href(from: progressLocation) else { return nil }
        let locations = chapters.compactMap { chapter -> String? in
            guard case .epub(let location) = chapter.target else { return nil }
            return location
        }
        guard
            let matchedLocation = EPUBResourceLocationMatcher().bestMatch(
                for: href,
                candidates: locations
            )
        else { return nil }

        return chapters.last { chapter in
            guard case .epub(let location) = chapter.target else { return false }
            return location == matchedLocation
        }?.id
    }

    func currentChapterID(
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
            guard let progressLocation,
                !progressLocation.hasPrefix("epubcfi(")
            else { return nil }
            return progressLocation
        }
        return href
    }

    private func normalizedResource(_ location: String) -> String {
        let withoutFragment = location.split(separator: "#", maxSplits: 1).first.map(String.init) ?? location
        return (withoutFragment.removingPercentEncoding ?? withoutFragment)
            .replacingOccurrences(of: "\\", with: "/")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            .lowercased()
    }

    private func cacheDirectory(bookID: UUID) -> URL {
        let root =
            FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return
            root
            .appending(path: "Prismedia", directoryHint: .isDirectory)
            .appending(path: "EPUBContents", directoryHint: .isDirectory)
            .appending(path: bookID.uuidString.lowercased(), directoryHint: .isDirectory)
    }
}
