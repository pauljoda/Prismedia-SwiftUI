import Foundation

/// Resolves a capability-advertised page manifest without materializing individual pages as
/// Entities. Prose books use their EPUB/PDF readers and never enter this resolver.
public struct BookReaderManifestResolver: Sendable {
    private let loader: any EntityDetailLoading

    public init(loader: any EntityDetailLoading) {
        self.loader = loader
    }

    public func resolve(selected: EntityDetail, command: BookReaderCommand) async throws -> BookReaderManifest {
        guard let reader = loader as? any EntityPageReaderServicing,
            let pageCapability = selected.capability(EntityPageSequenceCapability.self)
        else {
            throw BookReaderManifestError.unsupportedEntity(selected.kind)
        }

        let source = try await reader.loadEntityReaderManifest(id: selected.id)
        guard source.entityID == selected.id, !source.pages.isEmpty else {
            throw BookReaderManifestError.noReadablePages
        }
        let pages = source.pages
            .sorted { $0.ordinal < $1.ordinal }
            .map { BookReaderPage(entityID: selected.id, page: $0) }
        let progress: EntityProgressCapability? = selected.capability()
        let initialIndex: Int
        switch command {
        case .read:
            initialIndex = 0
        case .resume:
            let canResume = progress?.completedAt == nil && progress?.currentEntityID == selected.id
            initialIndex = canResume ? max(0, progress?.index ?? 0) : 0
        case .page(let index):
            initialIndex = index
        }
        let next = try? await followingOrderedItem(after: selected)
        return BookReaderManifest(
            bookID: selected.id,
            title: selected.title,
            chapters: [
                BookReaderChapter(
                    detail: selected,
                    readerPages: pages,
                    sequenceIndex: selected.sortOrder ?? 0
                )
            ],
            nextChapter: next,
            progress: progress,
            initialIndex: clamp(initialIndex, count: pages.count),
            readerMode: pageCapability.defaultMode == .webtoon ? .webtoon : .paged,
            readingDirection: source.direction,
            coverOrdinal: source.coverOrdinal,
            completesAtManifestEnd: true
        )
    }

    private func followingOrderedItem(after selected: EntityDetail) async throws -> BookChapterSummary? {
        guard let sequence = selected.capability(EntityOrderedSequenceCapability.self),
            sequence.role == .item
        else { return nil }

        let allowedContainers = Set(sequence.containerKinds)
        var root = selected
        var parentID = selected.parentEntityID
        while let id = parentID {
            let parent = try await loader.loadEntity(id: id)
            guard allowedContainers.contains(parent.kind) else { break }
            root = parent
            parentID = parent.parentEntityID
        }

        let items: [EntityThumbnail]
        if selected.parentEntityID == root.id {
            items = orderedChildren(in: root, kind: sequence.itemKind)
        } else {
            var containerThumbnails: [EntityThumbnail] = []
            for containerKind in sequence.containerKinds where containerKind != root.kind {
                containerThumbnails += orderedChildren(in: root, kind: containerKind)
            }
            containerThumbnails.sort(by: Self.sequenceOrder)
            var nestedItems: [EntityThumbnail] = []
            for container in try await loadDetails(containerThumbnails) {
                nestedItems += orderedChildren(in: container, kind: sequence.itemKind)
            }
            items = nestedItems
        }
        guard let currentIndex = items.firstIndex(where: { $0.id == selected.id }),
            items.indices.contains(currentIndex + 1)
        else { return nil }
        let nextIndex = currentIndex + 1
        let next = items[nextIndex]
        return BookChapterSummary(
            id: next.id,
            title: next.title,
            sortOrder: nextIndex,
            pageCount: 0
        )
    }

    private static func sequenceOrder(_ left: EntityThumbnail, _ right: EntityThumbnail) -> Bool {
        let leftOrder = left.sortOrder ?? Int.max
        let rightOrder = right.sortOrder ?? Int.max
        if leftOrder != rightOrder { return leftOrder < rightOrder }
        let title = left.title.localizedStandardCompare(right.title)
        if title != .orderedSame { return title == .orderedAscending }
        return left.id.uuidString < right.id.uuidString
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
        return entities.sorted(by: Self.sequenceOrder)
    }

    private func clamp(_ index: Int, count: Int) -> Int {
        max(0, min(index, max(0, count - 1)))
    }
}
