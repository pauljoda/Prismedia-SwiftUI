import Foundation
import Observation

@MainActor
@Observable
public final class EntityImageViewerSession {
    public var currentEntityID: UUID?
    public private(set) var sequence: EntityMediaSequence
    public private(set) var isLoadingNextPage = false
    public private(set) var paginationErrorMessage: String?

    @ObservationIgnored private let sequenceLoader: (any EntityMediaSequenceLoading)?
    @ObservationIgnored private let pagingPolicy: EntityImageViewerPagingPolicy
    @ObservationIgnored private var requestedCursors = Set<String>()
    @ObservationIgnored private var paginationTask: Task<Void, Never>?

    public init(
        selected: EntityThumbnail,
        sequence: EntityMediaSequence? = nil,
        sequenceLoader: (any EntityMediaSequenceLoading)? = nil,
        pagingPolicy: EntityImageViewerPagingPolicy = EntityImageViewerPagingPolicy()
    ) {
        let resolvedSequence =
            sequence?.items.contains(where: { $0.id == selected.id }) == true
            ? sequence!
            : EntityMediaSequence(items: [selected])
        currentEntityID = selected.id
        self.sequence = resolvedSequence
        self.sequenceLoader = sequenceLoader
        self.pagingPolicy = pagingPolicy
    }

    public var currentItem: EntityThumbnail? {
        guard let currentEntityID else { return nil }
        return sequence.items.first { $0.id == currentEntityID }
    }

    public func select(_ entityID: UUID) {
        guard sequence.index(of: entityID) != nil else { return }
        currentEntityID = entityID
    }

    public func loadNextPageIfNeeded() async {
        guard
            pagingPolicy.shouldLoadNextPage(
                activeEntityID: currentEntityID,
                sequence: sequence
            )
        else { return }
        if let paginationTask {
            await paginationTask.value
            return
        }
        guard let sequenceLoader, let request = sequence.nextPageRequest else { return }
        guard requestedCursors.insert(request.cursor).inserted else { return }

        isLoadingNextPage = true
        paginationErrorMessage = nil
        let task = Task { [weak self] in
            guard let self else { return }
            await self.loadNextPage(request, using: sequenceLoader)
        }
        paginationTask = task
        await task.value
    }

    private func loadNextPage(
        _ request: EntityMediaSequencePageRequest,
        using sequenceLoader: any EntityMediaSequenceLoading
    ) async {
        defer {
            isLoadingNextPage = false
            paginationTask = nil
        }
        do {
            let page = try await sequenceLoader.loadNextPage(request)
            let nextCursor = page.nextCursor.flatMap {
                requestedCursors.contains($0) ? nil : $0
            }
            sequence = sequence.appending(page, nextCursor: nextCursor)
        } catch is CancellationError {
            requestedCursors.remove(request.cursor)
        } catch {
            requestedCursors.remove(request.cursor)
            paginationErrorMessage = "More images couldn’t be loaded."
        }
    }
}
