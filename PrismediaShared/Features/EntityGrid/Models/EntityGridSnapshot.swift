import Foundation

public struct EntityGridSnapshot: Equatable, Sendable {
    public private(set) var activeSearch: String?
    public private(set) var items: [EntityThumbnail]
    public private(set) var totalCount: Int
    public private(set) var nextCursor: String?
    public private(set) var state: EntityGridState
    public private(set) var isRefreshing: Bool
    public private(set) var isLoadingNextPage: Bool
    public private(set) var errorMessage: String?
    public private(set) var paginationErrorMessage: String?
    public private(set) var controls: EntityGridControls

    public var hasNextPage: Bool { nextCursor != nil }

    private var generation: Int
    private var excludedNsfwIDs: Set<UUID>
    private var requestedCursors: Set<String>

    public init(
        configuration: EntityGridConfiguration,
        restoredControls: EntityGridControls? = nil
    ) {
        activeSearch = nil
        items = []
        totalCount = 0
        nextCursor = nil
        state = .idle
        isRefreshing = false
        isLoadingNextPage = false
        errorMessage = nil
        paginationErrorMessage = nil
        controls = restoredControls ?? configuration.defaultControls()
        generation = 0
        excludedNsfwIDs = []
        requestedCursors = []
    }

    /// Updates the normalized server-side search. Returns false when the
    /// effective query has not changed, allowing debounced work to be skipped.
    @discardableResult
    public mutating func setSearch(_ value: String) -> Bool {
        let normalized = Self.normalizedSearch(value)
        guard normalized != activeSearch else { return false }
        activeSearch = normalized
        return true
    }

    public mutating func setControls(_ controls: EntityGridControls) {
        self.controls = controls
    }

    public mutating func resetControls(for configuration: EntityGridConfiguration) {
        controls = configuration.defaultControls()
    }

    public mutating func reshuffle(
        randomSeed: Int = EntityGridControls.nextRandomSeed()
    ) -> Bool {
        guard controls.sort == .random else { return false }
        controls.randomSeed = randomSeed
        return true
    }

    public mutating func beginFirstPage(
        configuration: EntityGridConfiguration,
        pageSize: Int? = nil,
        preservingContent: Bool
    ) -> EntityGridPageRequest {
        generation &+= 1
        requestedCursors.removeAll(keepingCapacity: true)
        isLoadingNextPage = false
        paginationErrorMessage = nil
        errorMessage = nil

        if preservingContent, !items.isEmpty {
            isRefreshing = true
        } else {
            items = []
            totalCount = 0
            nextCursor = nil
            state = .loading
            excludedNsfwIDs = []
        }

        return request(
            configuration: configuration,
            pageSize: pageSize,
            cursor: nil,
            preservingContent: preservingContent
        )
    }

    public mutating func beginRefresh(
        configuration: EntityGridConfiguration,
        pageSize: Int? = nil,
        randomSeed: Int = EntityGridControls.nextRandomSeed()
    ) -> EntityGridPageRequest {
        _ = reshuffle(randomSeed: randomSeed)
        return beginFirstPage(
            configuration: configuration,
            pageSize: pageSize,
            preservingContent: !items.isEmpty
        )
    }

    public mutating func beginNextPage(
        configuration: EntityGridConfiguration,
        pageSize: Int? = nil
    ) -> EntityGridPageRequest? {
        guard let nextCursor, !isLoadingNextPage else { return nil }
        guard requestedCursors.insert(nextCursor).inserted else {
            self.nextCursor = nil
            return nil
        }
        isLoadingNextPage = true
        paginationErrorMessage = nil
        return request(
            configuration: configuration,
            pageSize: pageSize,
            cursor: nextCursor,
            preservingContent: true
        )
    }

    @discardableResult
    public mutating func receiveFirstPage(
        _ page: EntityGridPage,
        for request: EntityGridPageRequest
    ) -> Bool {
        guard request.generation == generation else { return false }
        items = page.items
        totalCount = page.totalCount
        nextCursor = page.nextCursor
        excludedNsfwIDs = page.excludedNsfwIDs
        state = items.isEmpty ? .empty : .content
        isRefreshing = false
        return true
    }

    @discardableResult
    public mutating func receiveNextPage(
        _ page: EntityGridPage,
        for request: EntityGridPageRequest
    ) -> Bool {
        guard request.generation == generation else { return false }
        items = Self.unique(items + page.items)
        totalCount = max(items.count, page.totalCount)
        nextCursor = page.nextCursor.flatMap { requestedCursors.contains($0) ? nil : $0 }
        excludedNsfwIDs = page.excludedNsfwIDs
        state = items.isEmpty ? .empty : .content
        isLoadingNextPage = false
        return true
    }

    @discardableResult
    public mutating func failFirstPage(
        title: String,
        for request: EntityGridPageRequest
    ) -> Bool {
        guard request.generation == generation else { return false }
        isRefreshing = false
        let message = "\(title) couldn’t be loaded. Try again."

        guard request.preservingContent, !items.isEmpty else {
            state = .failed(message)
            return true
        }

        state = .content
        errorMessage = message
        return true
    }

    @discardableResult
    public mutating func failNextPage(for request: EntityGridPageRequest) -> Bool {
        guard request.generation == generation else { return false }
        isLoadingNextPage = false
        if let cursor = request.cursor { requestedCursors.remove(cursor) }
        paginationErrorMessage = "More items couldn’t be loaded."
        return true
    }

    public mutating func cancel(_ request: EntityGridPageRequest) {
        guard request.generation == generation else { return }
        if request.cursor == nil {
            isRefreshing = false
        } else {
            isLoadingNextPage = false
            if let cursor = request.cursor { requestedCursors.remove(cursor) }
        }
    }

    public static func normalizedSearch(_ value: String) -> String? {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return normalized.isEmpty ? nil : normalized
    }

    public func mediaSequence(
        configuration: EntityGridConfiguration,
        pageSize: Int
    ) -> EntityMediaSequence {
        let continuation = nextCursor.map {
            EntityMediaSequenceContinuation(
                query: controls.applying(to: configuration.query),
                pageSize: pageSize,
                search: activeSearch,
                cursor: $0,
                existingItemIDs: Set(items.map(\.id)),
                excludedNsfwIDs: excludedNsfwIDs
            )
        }
        return EntityMediaSequence(items: items, continuation: continuation)
    }

    private func request(
        configuration: EntityGridConfiguration,
        pageSize: Int?,
        cursor: String?,
        preservingContent: Bool
    ) -> EntityGridPageRequest {
        let isFirstPage = cursor == nil
        return EntityGridPageRequest(
            generation: generation,
            query: controls.applying(to: configuration.query),
            pageSize: pageSize ?? configuration.pageSize,
            search: activeSearch,
            cursor: cursor,
            preservingContent: preservingContent,
            existingItemIDs: isFirstPage ? [] : Set(items.map(\.id)),
            excludedNsfwIDs: isFirstPage ? [] : excludedNsfwIDs
        )
    }

    private static func unique(_ candidates: [EntityThumbnail]) -> [EntityThumbnail] {
        var seen = Set<UUID>()
        return candidates.filter { seen.insert($0.id).inserted }
    }
}
