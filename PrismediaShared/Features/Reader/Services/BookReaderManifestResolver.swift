import Foundation

public struct BookReaderManifestResolver: Sendable {
    private let loader: any EntityDetailLoading

    public init(loader: any EntityDetailLoading) {
        self.loader = loader
    }

    public func resolve(selected: EntityDetail, command: BookReaderCommand) async throws -> BookReaderManifest {
        let book = try await owningBook(for: selected)
        guard book.bookFormat == .imageArchive else {
            throw BookReaderManifestError.unsupportedEntity(book.kind)
        }
        if selected.kind == .bookVolume {
            return try await volumeManifest(book: book, volume: selected, command: command)
        }

        let selectedChapter: EntityDetail?
        if selected.kind == .bookChapter {
            selectedChapter = selected
        } else if command == .resume, let chapterID = bookProgress(in: book)?.currentEntityID {
            selectedChapter = try await loader.loadEntity(id: chapterID)
        } else {
            selectedChapter = try await firstChapter(in: book)
        }
        guard let selectedChapter else { throw BookReaderManifestError.noReadablePages }
        return try await chapterManifest(book: book, chapter: selectedChapter, command: command)
    }

    private func owningBook(for selected: EntityDetail) async throws -> EntityDetail {
        if selected.kind == .book {
            return try await loader.loadEntity(id: selected.id, kind: .book)
        }
        guard let parentID = selected.parentEntityID else {
            throw BookReaderManifestError.missingParent(selected.kind)
        }
        let parent = try await loader.loadEntity(id: parentID)
        if parent.kind == .book {
            return try await loader.loadEntity(id: parent.id, kind: .book)
        }
        guard parent.kind == .bookVolume, let bookID = parent.parentEntityID else {
            throw BookReaderManifestError.missingBook
        }
        let book = try await loader.loadEntity(id: bookID, kind: .book)
        guard book.kind == .book else { throw BookReaderManifestError.missingBook }
        return book
    }

    private func volumeManifest(
        book: EntityDetail,
        volume: EntityDetail,
        command: BookReaderCommand
    ) async throws -> BookReaderManifest {
        let sequence = try await chapterSequence(in: book)
        let thumbnails = orderedChildren(in: volume, kind: .bookChapter)
        let details = try await loadDetails(thumbnails)
        let chapters = details.enumerated().map { index, detail in
            BookReaderChapter(
                detail: detail,
                pages: orderedChildren(in: detail, kind: .bookPage),
                sequenceIndex: sequence.firstIndex(where: { $0.id == detail.id }) ?? index
            )
        }
        guard !chapters.flatMap(\.pages).isEmpty else { throw BookReaderManifestError.noReadablePages }
        let progress = bookProgress(in: book)
        let progressOffset = pageOffset(chapters: chapters, chapterID: progress?.currentEntityID)
        let initialIndex =
            command == .resume && progress?.completedAt == nil && progressOffset != nil
            ? (progressOffset ?? 0) + max(0, progress?.index ?? 0)
            : 0
        let nextChapter = followingChapter(after: chapters.last?.id, in: sequence)
        return .init(
            bookID: book.id,
            title: "\(book.title) · \(volume.title)",
            chapters: chapters,
            nextChapter: nextChapter,
            progress: progress,
            initialIndex: clamp(initialIndex, count: chapters.flatMap(\.pages).count),
            readerMode: comicMode(progress?.mode)
        )
    }

    private func chapterManifest(
        book: EntityDetail,
        chapter: EntityDetail,
        command: BookReaderCommand
    ) async throws -> BookReaderManifest {
        let sequence = try await chapterSequence(in: book)
        let sequenceIndex = max(0, sequence.firstIndex(where: { $0.id == chapter.id }) ?? 0)
        let pages = orderedChildren(in: chapter, kind: .bookPage)
        guard !pages.isEmpty else { throw BookReaderManifestError.noReadablePages }
        let progress = bookProgress(in: book)
        let canResume = command == .resume && progress?.completedAt == nil && progress?.currentEntityID == chapter.id
        let initialIndex = canResume ? max(0, progress?.index ?? 0) : 0
        let next =
            sequence.indices.contains(sequenceIndex + 1)
            ? BookChapterSummary(
                id: sequence[sequenceIndex + 1].id,
                title: sequence[sequenceIndex + 1].title,
                sortOrder: sequenceIndex + 1,
                pageCount: 0
            )
            : nil
        return .init(
            bookID: book.id,
            title: "\(book.title) · \(chapter.title)",
            chapters: [.init(detail: chapter, pages: pages, sequenceIndex: sequenceIndex)],
            nextChapter: next,
            progress: progress,
            initialIndex: clamp(initialIndex, count: pages.count),
            readerMode: comicMode(progress?.mode)
        )
    }

    private func firstChapter(in book: EntityDetail) async throws -> EntityDetail? {
        guard let thumbnail = try await chapterSequence(in: book).first else { return nil }
        return try await loader.loadEntity(id: thumbnail.id)
    }

    private func chapterSequence(in book: EntityDetail) async throws -> [EntityThumbnail] {
        let direct = orderedChildren(in: book, kind: .bookChapter)
        if !direct.isEmpty { return direct }
        var chapters: [EntityThumbnail] = []
        for volume in try await loadDetails(orderedChildren(in: book, kind: .bookVolume)) {
            chapters += orderedChildren(in: volume, kind: .bookChapter)
        }
        return chapters
    }

    private func loadDetails(_ thumbnails: [EntityThumbnail]) async throws -> [EntityDetail] {
        var details: [EntityDetail] = []
        for thumbnail in thumbnails {
            details.append(try await loader.loadEntity(id: thumbnail.id))
        }
        return details
    }

    private func orderedChildren(in detail: EntityDetail, kind: EntityKind) -> [EntityThumbnail] {
        let entities = detail.childrenByKind.first(where: { $0.kind == kind })?.entities ?? []
        return entities.sorted {
            let left = $0.sortOrder ?? Int.max
            let right = $1.sortOrder ?? Int.max
            if left != right { return left < right }
            if $0.title != $1.title { return $0.title.localizedStandardCompare($1.title) == .orderedAscending }
            return $0.id.uuidString < $1.id.uuidString
        }
    }

    private func bookProgress(in book: EntityDetail) -> EntityProgressCapability? {
        book.capabilities.lazy.compactMap {
            guard case .progress(let progress) = $0 else { return nil }
            return progress
        }.first
    }

    private func pageOffset(chapters: [BookReaderChapter], chapterID: UUID?) -> Int? {
        guard let chapterID else { return nil }
        var offset = 0
        for chapter in chapters {
            if chapter.id == chapterID { return offset }
            offset += chapter.pages.count
        }
        return nil
    }

    private func followingChapter(
        after chapterID: UUID?,
        in sequence: [EntityThumbnail]
    ) -> BookChapterSummary? {
        guard let chapterID,
            let currentIndex = sequence.firstIndex(where: { $0.id == chapterID }),
            sequence.indices.contains(currentIndex + 1)
        else { return nil }

        let nextIndex = currentIndex + 1
        let next = sequence[nextIndex]
        return BookChapterSummary(
            id: next.id,
            title: next.title,
            sortOrder: nextIndex,
            pageCount: 0
        )
    }

    private func comicMode(_ mode: ReaderMode?) -> ReaderMode {
        mode == .webtoon ? .webtoon : .paged
    }

    private func clamp(_ index: Int, count: Int) -> Int {
        max(0, min(index, max(0, count - 1)))
    }
}
