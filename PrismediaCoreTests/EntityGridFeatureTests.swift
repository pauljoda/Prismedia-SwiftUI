import XCTest

@testable import PrismediaCore

final class EntityGridFeatureTests: XCTestCase {
    @MainActor
    func testInitialLoadProducesSafeItemsAndAdjustedTotal() async {
        let safe = gridThumbnail(id: 1, title: "Arrival")
        let unsafe = gridThumbnail(id: 2, title: "Hidden", isNsfw: true)
        let loader = EntityGridLoaderStub(results: [
            .success(EntityListResponse(items: [safe, unsafe], nextCursor: "page-2", totalCount: 8))
        ])
        let service = EntityGridService(loader: loader)
        var snapshot = EntityGridSnapshot(configuration: gridConfiguration)

        snapshot = await loadFirstPage(snapshot, service: service)

        XCTAssertEqual(snapshot.items, [safe])
        XCTAssertEqual(snapshot.totalCount, 7)
        XCTAssertEqual(snapshot.nextCursor, "page-2")
        XCTAssertEqual(snapshot.state, .content)
        XCTAssertFalse(snapshot.items.contains(where: \.isNsfw))
    }

    @MainActor
    func testInitialLoadKeepsNsfwItemsWhenTheGlobalPreferenceAllowsThem() async {
        let safe = gridThumbnail(id: 1, title: "Arrival")
        let unsafe = gridThumbnail(id: 2, title: "Visible", isNsfw: true)
        let loader = EntityGridLoaderStub(
            results: [.success(EntityListResponse(items: [safe, unsafe], totalCount: 2))],
            allowsNsfwContent: true
        )
        let service = EntityGridService(loader: loader)
        var snapshot = EntityGridSnapshot(configuration: gridConfiguration)

        snapshot = await loadFirstPage(snapshot, service: service)

        XCTAssertEqual(snapshot.items, [safe, unsafe])
        XCTAssertEqual(snapshot.totalCount, 2)
    }

    @MainActor
    func testLoadingNextPageAppendsUniqueItemsAndUsesCursor() async {
        let first = gridThumbnail(id: 1, title: "One")
        let second = gridThumbnail(id: 2, title: "Two")
        let loader = EntityGridLoaderStub(results: [
            .success(EntityListResponse(items: [first], nextCursor: "page-2", totalCount: 2)),
            .success(EntityListResponse(items: [first, second], totalCount: 2)),
        ])
        let service = EntityGridService(loader: loader)
        var snapshot = EntityGridSnapshot(configuration: gridConfiguration)

        snapshot = await loadFirstPage(snapshot, service: service)
        snapshot = await loadNextPage(snapshot, service: service)

        XCTAssertEqual(snapshot.items, [first, second])
        XCTAssertNil(snapshot.nextCursor)
        XCTAssertEqual(snapshot.totalCount, 2)
        let requests = await loader.recordedRequests()
        XCTAssertEqual(requests.map(\.cursor), [nil, "page-2"])
    }

    @MainActor
    func testSearchTrimsQueryStartsAtFirstPageAndSkipsUnchangedTerm() async {
        let initial = gridThumbnail(id: 1, title: "Initial")
        let match = gridThumbnail(id: 2, title: "The Matrix")
        let loader = EntityGridLoaderStub(results: [
            .success(EntityListResponse(items: [initial], nextCursor: "unused")),
            .success(EntityListResponse(items: [match], totalCount: 1)),
        ])
        let service = EntityGridService(loader: loader)
        var snapshot = EntityGridSnapshot(configuration: gridConfiguration)

        snapshot = await loadFirstPage(snapshot, service: service)
        XCTAssertTrue(snapshot.setSearch("  matrix  "))
        snapshot = await loadFirstPage(snapshot, service: service)
        XCTAssertFalse(snapshot.setSearch("matrix"))

        XCTAssertEqual(snapshot.items, [match])
        XCTAssertEqual(snapshot.activeSearch, "matrix")
        let requests = await loader.recordedRequests()
        XCTAssertEqual(requests.map(\.search), [nil, "matrix"])
        XCTAssertEqual(requests.map(\.cursor), [nil, nil])
    }

    @MainActor
    func testAppendFailurePreservesContentAndCanBeRetried() async {
        let first = gridThumbnail(id: 1, title: "One")
        let second = gridThumbnail(id: 2, title: "Two")
        let loader = EntityGridLoaderStub(results: [
            .success(EntityListResponse(items: [first], nextCursor: "page-2", totalCount: 2)),
            .failure(.unavailable),
            .success(EntityListResponse(items: [second], totalCount: 2)),
        ])
        let service = EntityGridService(loader: loader)
        var snapshot = EntityGridSnapshot(configuration: gridConfiguration)

        snapshot = await loadFirstPage(snapshot, service: service)
        snapshot = await loadNextPage(snapshot, service: service)

        XCTAssertEqual(snapshot.items, [first])
        XCTAssertEqual(snapshot.paginationErrorMessage, "More items couldn’t be loaded.")
        XCTAssertEqual(snapshot.state, .content)

        snapshot = await loadNextPage(snapshot, service: service)

        XCTAssertEqual(snapshot.items, [first, second])
        XCTAssertNil(snapshot.paginationErrorMessage)
        let requests = await loader.recordedRequests()
        XCTAssertEqual(requests.map(\.cursor), [nil, "page-2", "page-2"])
    }

    @MainActor
    func testDuplicateOnlyPageContinuesUntilItFindsANewVisibleItem() async {
        let first = gridThumbnail(id: 1, title: "One")
        let second = gridThumbnail(id: 2, title: "Two")
        let loader = EntityGridLoaderStub(results: [
            .success(EntityListResponse(items: [first], nextCursor: "page-2", totalCount: 2)),
            .success(EntityListResponse(items: [first], nextCursor: "page-3", totalCount: 2)),
            .success(EntityListResponse(items: [second], totalCount: 2)),
        ])
        let service = EntityGridService(loader: loader)
        var snapshot = EntityGridSnapshot(configuration: gridConfiguration)

        snapshot = await loadFirstPage(snapshot, service: service)
        snapshot = await loadNextPage(snapshot, service: service)

        XCTAssertEqual(snapshot.items, [first, second])
        XCTAssertNil(snapshot.nextCursor)
        let requests = await loader.recordedRequests()
        XCTAssertEqual(requests.map(\.cursor), [nil, "page-2", "page-3"])
    }

    @MainActor
    func testCursorCycleTerminatesPaginationWithinTheGeneration() async {
        let first = gridThumbnail(id: 1, title: "One")
        let second = gridThumbnail(id: 2, title: "Two")
        let third = gridThumbnail(id: 3, title: "Three")
        let loader = EntityGridLoaderStub(results: [
            .success(EntityListResponse(items: [first], nextCursor: "page-a", totalCount: 4)),
            .success(EntityListResponse(items: [second], nextCursor: "page-b", totalCount: 4)),
            .success(EntityListResponse(items: [third], nextCursor: "page-a", totalCount: 4)),
        ])
        let service = EntityGridService(loader: loader)
        var snapshot = EntityGridSnapshot(configuration: gridConfiguration)

        snapshot = await loadFirstPage(snapshot, service: service)
        snapshot = await loadNextPage(snapshot, service: service)
        snapshot = await loadNextPage(snapshot, service: service)

        XCTAssertEqual(snapshot.items, [first, second, third])
        XCTAssertFalse(snapshot.hasNextPage)
        XCTAssertNil(snapshot.beginNextPage(configuration: gridConfiguration))
        let requests = await loader.recordedRequests()
        XCTAssertEqual(requests.map(\.cursor), [nil, "page-a", "page-b"])
    }

    @MainActor
    func testApplyingControlsReloadsAndPreservesThemAcrossPagination() async {
        let first = gridThumbnail(id: 1, title: "One")
        let second = gridThumbnail(id: 2, title: "Two")
        let loader = EntityGridLoaderStub(results: [
            .success(EntityListResponse(items: [first])),
            .success(EntityListResponse(items: [first], nextCursor: "filtered-page-2")),
            .success(EntityListResponse(items: [second])),
        ])
        let service = EntityGridService(loader: loader)
        var snapshot = EntityGridSnapshot(configuration: gridConfiguration)

        snapshot = await loadFirstPage(snapshot, service: service)
        var controls = snapshot.controls
        controls.sort = .rating
        controls.sortDescending = false
        controls.filters.favoriteOnly = true
        snapshot.setControls(controls)
        snapshot = await loadFirstPage(snapshot, service: service)
        snapshot = await loadNextPage(snapshot, service: service)

        let requests = await loader.recordedRequests()
        XCTAssertEqual(requests.map(\.query.sort), [nil, "rating", "rating"])
        XCTAssertEqual(requests.map(\.query.sortDescending), [true, false, false])
        XCTAssertEqual(requests.map(\.query.favorite), [nil, true, true])
        XCTAssertEqual(requests.map(\.cursor), [nil, nil, "filtered-page-2"])
    }

    @MainActor
    func testSupersededFirstPageCannotOverwriteCurrentSnapshot() {
        var snapshot = EntityGridSnapshot(configuration: gridConfiguration)
        let staleRequest = snapshot.beginFirstPage(
            configuration: gridConfiguration,
            preservingContent: false
        )
        _ = snapshot.beginFirstPage(
            configuration: gridConfiguration,
            preservingContent: false
        )
        let staleItem = gridThumbnail(id: 99, title: "Stale")
        let stalePage = EntityGridPage(
            items: [staleItem],
            nextCursor: nil,
            totalCount: 1,
            excludedNsfwIDs: []
        )

        XCTAssertFalse(snapshot.receiveFirstPage(stalePage, for: staleRequest))
        XCTAssertTrue(snapshot.items.isEmpty)
        XCTAssertEqual(snapshot.state, .loading)
    }

    func testRandomRefreshStartsOverWithFreshSeedAndKeepsItAcrossPagination() throws {
        var snapshot = EntityGridSnapshot(configuration: gridConfiguration)
        var controls = snapshot.controls
        controls.sort = .random
        controls.randomSeed = 101
        snapshot.setControls(controls)
        let initialRequest = snapshot.beginFirstPage(
            configuration: gridConfiguration,
            preservingContent: false
        )

        XCTAssertEqual(initialRequest.query.seed, 101)
        let refreshRequest = snapshot.beginRefresh(
            configuration: gridConfiguration,
            randomSeed: 202
        )
        let refreshedPage = EntityGridPage(
            items: [gridThumbnail(id: 1, title: "One")],
            nextCursor: "fresh-page-2",
            totalCount: 2,
            excludedNsfwIDs: []
        )
        snapshot.receiveFirstPage(refreshedPage, for: refreshRequest)
        let nextRequest = try XCTUnwrap(snapshot.beginNextPage(configuration: gridConfiguration))

        XCTAssertNil(refreshRequest.cursor)
        XCTAssertEqual(refreshRequest.query.seed, 202)
        XCTAssertEqual(nextRequest.query.seed, 202)
        XCTAssertEqual(nextRequest.cursor, "fresh-page-2")
    }

}

@MainActor
private func loadFirstPage(
    _ initialSnapshot: EntityGridSnapshot,
    service: EntityGridService,
    configuration: EntityGridConfiguration = gridConfiguration,
    preservingContent: Bool = false
) async -> EntityGridSnapshot {
    var snapshot = initialSnapshot
    let request = snapshot.beginFirstPage(
        configuration: configuration,
        preservingContent: preservingContent
    )

    do {
        let page = try await service.loadFirstPage(request)
        snapshot.receiveFirstPage(page, for: request)
    } catch {
        snapshot.failFirstPage(title: configuration.title, for: request)
    }
    return snapshot
}

@MainActor
private func loadNextPage(
    _ initialSnapshot: EntityGridSnapshot,
    service: EntityGridService,
    configuration: EntityGridConfiguration = gridConfiguration
) async -> EntityGridSnapshot {
    var snapshot = initialSnapshot
    guard let request = snapshot.beginNextPage(configuration: configuration) else { return snapshot }

    do {
        let page = try await service.loadNextVisiblePage(request)
        snapshot.receiveNextPage(page, for: request)
    } catch {
        snapshot.failNextPage(for: request)
    }
    return snapshot
}

private let gridConfiguration = EntityGridConfiguration(
    title: "Videos",
    query: EntityListQuery(kind: .video),
    supportsSearch: true,
    pageSize: 24
)

private enum EntityGridStubError: Error, Sendable {
    case unavailable
}

private struct EntityGridLoadRequest: Equatable, Sendable {
    let query: EntityListQuery
    let search: String?
    let cursor: String?
    let limit: Int
}

private actor EntityGridLoaderStub: EntityGridLoading {
    private var results: [Result<EntityListResponse, EntityGridStubError>]
    private var requests: [EntityGridLoadRequest] = []

    nonisolated let allowsNsfwContent: Bool

    init(
        results: [Result<EntityListResponse, EntityGridStubError>],
        allowsNsfwContent: Bool = false
    ) {
        self.results = results
        self.allowsNsfwContent = allowsNsfwContent
    }

    func load(
        query: EntityListQuery,
        limit: Int,
        search: String?,
        cursor: String?
    ) async throws -> EntityListResponse {
        requests.append(EntityGridLoadRequest(query: query, search: search, cursor: cursor, limit: limit))
        guard !results.isEmpty else { return EntityListResponse(items: []) }
        return try results.removeFirst().get()
    }

    func recordedRequests() -> [EntityGridLoadRequest] {
        requests
    }
}

private func gridThumbnail(id: Int, title: String, isNsfw: Bool = false) -> EntityThumbnail {
    EntityThumbnail(
        id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", id))!,
        kind: .video,
        title: title,
        isNsfw: isNsfw
    )
}
