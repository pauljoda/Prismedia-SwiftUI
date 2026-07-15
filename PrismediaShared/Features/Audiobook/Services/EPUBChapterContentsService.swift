import Foundation

struct EPUBChapterContentsService: Sendable {
    private let reader: any BookReaderServicing

    init(reader: any BookReaderServicing) {
        self.reader = reader
    }

    func load(book: EntityDetail) async throws -> EPUBChapterContents {
        let data = try await reader.loadSourceData(id: book.id)
        let title = book.title
        let destination = cacheDirectory(bookID: book.id)
        let publication = try await Task.detached(priority: .userInitiated) {
            try EPUBPublicationLoader().load(
                data: data,
                fallbackTitle: title,
                destination: destination
            )
        }.value
        let chapters = flattenedChapters(publication.tableOfContents)
        return EPUBChapterContents(
            chapters: chapters,
            currentChapterID: currentChapterID(
                progressLocation: book.capability(EntityProgressCapability.self)?.location,
                chapters: chapters
            )
        )
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

    private func currentChapterID(
        progressLocation: String?,
        chapters: [ReadableBookChapter]
    ) -> String? {
        guard let href = href(from: progressLocation) else { return nil }
        let resource = normalizedResource(href)
        return chapters.last { chapter in
            guard case .epub(let location) = chapter.target else { return false }
            return normalizedResource(location) == resource
        }?.id
    }

    private func href(from progressLocation: String?) -> String? {
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
        return root
            .appending(path: "Prismedia", directoryHint: .isDirectory)
            .appending(path: "EPUBContents", directoryHint: .isDirectory)
            .appending(path: bookID.uuidString.lowercased(), directoryHint: .isDirectory)
    }
}
