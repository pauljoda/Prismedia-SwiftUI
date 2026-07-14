import Foundation
import XCTest

@testable import PrismediaCore

final class SearchHubFeatureTests: XCTestCase {
    @MainActor
    func testLoadRecentProducesItemsAndTotalCount() async {
        let recent = [thumbnail(id: 1, title: "Arrival"), thumbnail(id: 2, title: "Severance")]
        let loader = SearchHubLoaderStub(
            recentResults: [.success(EntityListResponse(items: recent, totalCount: 14))]
        )
        let service = SearchHubService(loader: loader)
        var snapshot = SearchHubSnapshot()

        snapshot = await loadRecent(snapshot, service: service)

        XCTAssertEqual(snapshot.recentItems, recent)
        XCTAssertEqual(snapshot.recentTotalCount, 14)
        XCTAssertEqual(snapshot.recentState, .content)
        XCTAssertEqual(snapshot.activeState(for: ""), .content)
        XCTAssertEqual(snapshot.displayedItems(for: ""), recent)
        let requestedLimits = await loader.requestedRecentLimits()
        XCTAssertEqual(requestedLimits, [48])
    }

    @MainActor
    func testLoadRecentProducesEmptyAndFailureStates() async {
        let loader = SearchHubLoaderStub(
            recentResults: [
                .success(EntityListResponse(items: [])),
                .failure(.unavailable),
            ]
        )
        let service = SearchHubService(loader: loader)
        var snapshot = SearchHubSnapshot()

        snapshot = await loadRecent(snapshot, service: service)
        XCTAssertEqual(snapshot.recentState, .empty)

        snapshot = await loadRecent(snapshot, service: service)
        XCTAssertEqual(snapshot.recentState, .failed("Your library couldn’t be loaded. Try again."))
        XCTAssertTrue(snapshot.recentItems.isEmpty)
        XCTAssertEqual(snapshot.recentTotalCount, 0)
    }

    @MainActor
    func testRecentLoadDropsUnexpectedNsfwItemsAndAdjustsVisibleTotal() async {
        let safe = thumbnail(id: 12, title: "Safe")
        let unsafe = thumbnail(id: 13, title: "Unsafe", isNsfw: true)
        let loader = SearchHubLoaderStub(
            recentResults: [.success(EntityListResponse(items: [safe, unsafe], totalCount: 8))]
        )
        let service = SearchHubService(loader: loader)
        var snapshot = SearchHubSnapshot()

        snapshot = await loadRecent(snapshot, service: service)

        XCTAssertEqual(snapshot.recentItems, [safe])
        XCTAssertEqual(snapshot.recentTotalCount, 7)
        XCTAssertEqual(snapshot.recentState, .content)
        XCTAssertFalse(snapshot.displayedItems(for: "").contains(where: \.isNsfw))
    }

    @MainActor
    func testRecentLoadKeepsNsfwItemsWhenPreferenceAllowsThem() async {
        let safe = thumbnail(id: 12, title: "Safe")
        let unsafe = thumbnail(id: 13, title: "Visible", isNsfw: true)
        let loader = SearchHubLoaderStub(
            recentResults: [.success(EntityListResponse(items: [safe, unsafe], totalCount: 2))],
            allowsNsfwContent: true
        )
        let service = SearchHubService(loader: loader)
        var snapshot = SearchHubSnapshot()

        snapshot = await loadRecent(snapshot, service: service)

        XCTAssertEqual(snapshot.recentItems, [safe, unsafe])
        XCTAssertEqual(snapshot.recentTotalCount, 2)
    }

    @MainActor
    func testSearchServiceDebouncesAndSnapshotReceivesResults() async throws {
        let result = thumbnail(id: 3, title: "The Matrix")
        let loader = SearchHubLoaderStub(
            searchResults: ["matrix": .success(EntityListResponse(items: [result], totalCount: 3))]
        )
        let service = SearchHubService(loader: loader, searchLimit: 20)
        var snapshot = SearchHubSnapshot()
        let request = try XCTUnwrap(snapshot.beginSearch(query: "  matrix  "))

        let loading = Task {
            try await service.search(query: request.query, debounce: .milliseconds(40))
        }
        try await Task.sleep(for: .milliseconds(10))
        let searchesBeforeDebounce = await loader.requestedSearches()
        XCTAssertEqual(searchesBeforeDebounce, [])
        let page = try await loading.value
        snapshot.receiveSearch(page, for: request, currentQuery: "matrix")

        let completedSearches = await loader.requestedSearches()
        XCTAssertEqual(completedSearches, [SearchRequest(query: "matrix", limit: 20, cursor: nil)])
        XCTAssertEqual(snapshot.searchResults, [result])
        XCTAssertEqual(snapshot.searchTotalCount, 3)
        XCTAssertEqual(snapshot.activeState(for: "matrix"), .content)
        XCTAssertEqual(snapshot.displayedItems(for: "matrix"), [result])
    }

    @MainActor
    func testSearchContainingOnlyUnexpectedNsfwItemsProducesSafeEmptyState() async throws {
        let unsafe = thumbnail(id: 14, title: "Unsafe Search Result", isNsfw: true)
        let loader = SearchHubLoaderStub(
            searchResults: ["unsafe": .success(EntityListResponse(items: [unsafe], totalCount: 1))]
        )
        let service = SearchHubService(loader: loader)
        var snapshot = SearchHubSnapshot()
        let request = try XCTUnwrap(snapshot.beginSearch(query: "unsafe"))

        let page = try await service.search(query: request.query, debounce: .zero)
        snapshot.receiveSearch(page, for: request, currentQuery: "unsafe")

        XCTAssertTrue(snapshot.searchResults.isEmpty)
        XCTAssertEqual(snapshot.searchTotalCount, 0)
        XCTAssertEqual(snapshot.searchState, .empty)
    }

    @MainActor
    func testLatestQueryWinsWhenAnOlderLoaderIgnoresCancellation() async throws {
        let oldResult = thumbnail(id: 4, title: "Old Result")
        let newResult = thumbnail(id: 5, title: "New Result")
        let loader = SearchHubLoaderStub(
            searchResults: [
                "old": .success(EntityListResponse(items: [oldResult])),
                "new": .success(EntityListResponse(items: [newResult])),
            ],
            searchDelays: [
                "old": .milliseconds(120),
                "new": .milliseconds(5),
            ]
        )
        let service = SearchHubService(loader: loader)
        var snapshot = SearchHubSnapshot()
        let oldRequest = try XCTUnwrap(snapshot.beginSearch(query: "old"))
        let oldTask = Task { try await service.search(query: oldRequest.query, debounce: .zero) }
        try await Task.sleep(for: .milliseconds(10))
        let newRequest = try XCTUnwrap(snapshot.beginSearch(query: "new"))
        let newPage = try await service.search(query: newRequest.query, debounce: .zero)

        XCTAssertTrue(snapshot.receiveSearch(newPage, for: newRequest, currentQuery: "new"))
        XCTAssertEqual(snapshot.searchResults, [newResult])

        let oldPage = try await oldTask.value
        XCTAssertFalse(snapshot.receiveSearch(oldPage, for: oldRequest, currentQuery: "new"))
        XCTAssertEqual(snapshot.searchResults, [newResult])
    }

    @MainActor
    func testRefiningQueryKeepsCurrentResultsWhileNextRequestLoads() async throws {
        let broadResult = thumbnail(id: 10, title: "Star Trek")
        let loader = SearchHubLoaderStub(
            searchResults: ["star": .success(EntityListResponse(items: [broadResult]))]
        )
        let service = SearchHubService(loader: loader)
        var snapshot = SearchHubSnapshot()
        let broadRequest = try XCTUnwrap(snapshot.beginSearch(query: "star"))
        let broadPage = try await service.search(query: broadRequest.query, debounce: .zero)
        snapshot.receiveSearch(broadPage, for: broadRequest, currentQuery: "star")

        _ = snapshot.beginSearch(query: "star trek")

        XCTAssertEqual(snapshot.searchState, .loading)
        XCTAssertEqual(snapshot.searchResults, [broadResult])
    }

    @MainActor
    func testSearchPaginationAppendsUniqueResultsUsingTheServerCursor() async throws {
        let first = thumbnail(id: 20, title: "First")
        let duplicate = thumbnail(id: 20, title: "First")
        let second = thumbnail(id: 21, title: "Second")
        let loader = SearchHubLoaderStub(
            queuedSearchResults: [
                "matrix": [
                    .success(
                        EntityListResponse(
                            items: [first],
                            nextCursor: "page-2",
                            totalCount: 2
                        )
                    ),
                    .success(EntityListResponse(items: [duplicate, second], totalCount: 2)),
                ]
            ]
        )
        let service = SearchHubService(loader: loader, searchLimit: 20)
        var snapshot = SearchHubSnapshot()
        let firstRequest = try XCTUnwrap(snapshot.beginSearch(query: "matrix"))
        let firstPage = try await service.search(request: firstRequest, debounce: .zero)
        snapshot.receiveSearch(firstPage, for: firstRequest, currentQuery: "matrix")
        let nextRequest = try XCTUnwrap(snapshot.beginNextSearchPage(currentQuery: "matrix"))
        let nextPage = try await service.search(request: nextRequest, debounce: .zero)
        snapshot.receiveNextSearchPage(nextPage, for: nextRequest, currentQuery: "matrix")

        XCTAssertEqual(snapshot.searchResults, [first, second])
        XCTAssertFalse(snapshot.hasMoreSearchResults)
        XCTAssertFalse(snapshot.isLoadingNextSearchPage)
        let requestedSearches = await loader.requestedSearches()
        XCTAssertEqual(
            requestedSearches,
            [
                SearchRequest(query: "matrix", limit: 20, cursor: nil),
                SearchRequest(query: "matrix", limit: 20, cursor: "page-2"),
            ]
        )
    }

    @MainActor
    func testClearingSearchInvalidatesPendingWorkAndRestoresRecentContent() async throws {
        let recent = thumbnail(id: 6, title: "Recent")
        let loader = SearchHubLoaderStub(
            recentResults: [.success(EntityListResponse(items: [recent]))],
            searchResults: ["pending": .success(EntityListResponse(items: [thumbnail(id: 7, title: "Pending")]))]
        )
        let service = SearchHubService(loader: loader)
        var snapshot = await loadRecent(SearchHubSnapshot(), service: service)
        let request = try XCTUnwrap(snapshot.beginSearch(query: "pending"))
        let loading = Task {
            try await service.search(query: request.query, debounce: .milliseconds(80))
        }

        loading.cancel()
        snapshot.clearSearch()
        _ = try? await loading.value

        XCTAssertEqual(snapshot.searchState, .idle)
        XCTAssertTrue(snapshot.searchResults.isEmpty)
        XCTAssertEqual(snapshot.activeState(for: ""), .content)
        XCTAssertEqual(snapshot.displayedItems(for: ""), [recent])
        let searches = await loader.requestedSearches()
        XCTAssertEqual(searches, [])
    }

    @MainActor
    func testResetInvalidatesInFlightRecentLoad() async throws {
        let loader = SearchHubLoaderStub(
            recentResults: [.success(EntityListResponse(items: [thumbnail(id: 8, title: "Too Late")]))],
            recentDelay: .milliseconds(60)
        )
        let service = SearchHubService(loader: loader)
        var snapshot = SearchHubSnapshot()
        let request = snapshot.beginRecentLoad()
        let loading = Task { try await service.loadRecent() }

        snapshot.reset()
        let page = try await loading.value

        XCTAssertFalse(snapshot.receiveRecent(page, for: request))
        XCTAssertEqual(snapshot.recentState, .idle)
        XCTAssertEqual(snapshot.searchState, .idle)
        XCTAssertTrue(snapshot.recentItems.isEmpty)
    }

    @MainActor
    func testRetryImmediatelyRepeatsActiveSearch() async throws {
        let result = thumbnail(id: 9, title: "Recovered")
        let loader = SearchHubLoaderStub(
            queuedSearchResults: [
                "recover": [
                    .failure(.unavailable),
                    .success(EntityListResponse(items: [result])),
                ]
            ]
        )
        let service = SearchHubService(loader: loader)
        var snapshot = SearchHubSnapshot()
        var request = try XCTUnwrap(snapshot.beginSearch(query: "recover"))

        do {
            _ = try await service.search(query: request.query, debounce: .zero)
            XCTFail("The first request should fail")
        } catch {
            snapshot.failSearch(for: request, currentQuery: "recover")
        }
        XCTAssertEqual(snapshot.searchState, .failed("Search couldn’t be completed. Try again."))

        request = try XCTUnwrap(snapshot.beginSearch(query: "recover"))
        let page = try await service.search(query: request.query, debounce: .zero)
        snapshot.receiveSearch(page, for: request, currentQuery: "recover")

        XCTAssertEqual(snapshot.searchResults, [result])
        XCTAssertEqual(snapshot.searchState, .content)
    }

    func testPrismediaLoaderBuildsPreviewAndUniversalSearchRequests() async throws {
        let dataLoader = MockHTTPDataLoader(responses: [
            .json(#"{"items":[],"nextCursor":null,"totalCount":0}"#),
            .json(#"{"items":[],"nextCursor":null,"totalCount":0}"#),
            .json(#"{"items":[],"nextCursor":null,"totalCount":0}"#),
            .json(#"{"items":[],"nextCursor":null,"totalCount":0}"#),
            .json(#"{"items":[],"nextCursor":null,"totalCount":0}"#),
            .json(#"{"items":[],"nextCursor":null,"totalCount":0}"#),
            .json(#"{"items":[],"nextCursor":null,"totalCount":0}"#),
        ])
        let client = PrismediaAPIClient(
            serverURL: URL(string: "https://media.example.test")!,
            accessToken: "token",
            loader: dataLoader
        )
        let loader = PrismediaSearchHubLoader(client: client)

        _ = try await loader.loadRecent(limit: 12)
        _ = try await loader.search(query: "matrix", limit: 20, cursor: nil)
        _ = try await loader.search(query: "matrix", limit: 20, cursor: "page-2")

        let previewRequests = dataLoader.requests.dropLast(2)
        let previewQueries = previewRequests.compactMap { request in
            request.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }
                .map { queryDictionary($0.queryItems ?? []) }
        }
        XCTAssertEqual(
            Set(previewQueries.compactMap { $0["kind"] }), Set(SearchHubCatalog.previewKinds.map(\.rawValue)))
        XCTAssertTrue(previewQueries.allSatisfy { $0["sort"] == "added" })
        XCTAssertTrue(previewQueries.allSatisfy { $0["sortDir"] == "desc" })
        XCTAssertTrue(previewQueries.allSatisfy { $0["limit"] == "2" })
        XCTAssertTrue(previewQueries.allSatisfy { $0["hideNsfw"] == "true" })

        let searchRequests = dataLoader.requests.suffix(2)
        let searchQueries = searchRequests.compactMap { request in
            request.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }
                .map { queryDictionary($0.queryItems ?? []) }
        }
        XCTAssertEqual(searchQueries.map { $0["query"] }, ["matrix", "matrix"])
        XCTAssertEqual(searchQueries.map { $0["limit"] }, ["20", "20"])
        XCTAssertTrue(searchQueries.allSatisfy { $0["hideNsfw"] == "true" })
        XCTAssertTrue(searchQueries.allSatisfy { $0["nsfw"] == "false" })
        XCTAssertTrue(
            searchQueries.allSatisfy { $0["kind"] == nil },
            "Search must span every visible entity kind."
        )
        XCTAssertNil(searchQueries[0]["cursor"])
        XCTAssertEqual(searchQueries[1]["cursor"], "page-2")
    }
}

@MainActor
private func loadRecent(
    _ initialSnapshot: SearchHubSnapshot,
    service: SearchHubService
) async -> SearchHubSnapshot {
    var snapshot = initialSnapshot
    let request = snapshot.beginRecentLoad()
    do {
        let page = try await service.loadRecent()
        snapshot.receiveRecent(page, for: request)
    } catch {
        snapshot.failRecent(for: request)
    }
    return snapshot
}

private enum SearchHubStubError: Error, Sendable {
    case unavailable
}

private struct SearchRequest: Equatable, Sendable {
    let query: String
    let limit: Int
    let cursor: String?
}

private actor SearchHubLoaderStub: SearchHubLoading {
    private var recentResults: [Result<EntityListResponse, SearchHubStubError>]
    private var searchResults: [String: Result<EntityListResponse, SearchHubStubError>]
    private var queuedSearchResults: [String: [Result<EntityListResponse, SearchHubStubError>]]
    private let recentDelay: Duration
    private let searchDelays: [String: Duration]
    private var recentLimits: [Int] = []
    private var searches: [SearchRequest] = []
    nonisolated let allowsNsfwContent: Bool

    init(
        recentResults: [Result<EntityListResponse, SearchHubStubError>] = [],
        searchResults: [String: Result<EntityListResponse, SearchHubStubError>] = [:],
        queuedSearchResults: [String: [Result<EntityListResponse, SearchHubStubError>]] = [:],
        recentDelay: Duration = .zero,
        searchDelays: [String: Duration] = [:],
        allowsNsfwContent: Bool = false
    ) {
        self.recentResults = recentResults
        self.searchResults = searchResults
        self.queuedSearchResults = queuedSearchResults
        self.recentDelay = recentDelay
        self.searchDelays = searchDelays
        self.allowsNsfwContent = allowsNsfwContent
    }

    func loadRecent(limit: Int) async throws -> EntityListResponse {
        recentLimits.append(limit)
        await nonCancellablePause(for: recentDelay)
        guard !recentResults.isEmpty else { return EntityListResponse(items: []) }
        return try recentResults.removeFirst().get()
    }

    func search(query: String, limit: Int, cursor: String?) async throws -> EntityListResponse {
        searches.append(SearchRequest(query: query, limit: limit, cursor: cursor))
        await nonCancellablePause(for: searchDelays[query] ?? .zero)

        if var queued = queuedSearchResults[query], !queued.isEmpty {
            let result = queued.removeFirst()
            queuedSearchResults[query] = queued
            return try result.get()
        }

        guard let result = searchResults[query] else { return EntityListResponse(items: []) }
        return try result.get()
    }

    func requestedRecentLimits() -> [Int] {
        recentLimits
    }

    func requestedSearches() -> [SearchRequest] {
        searches
    }

    private func nonCancellablePause(for duration: Duration) async {
        guard duration > .zero else { return }
        await Task.detached {
            try? await Task.sleep(for: duration)
        }.value
    }
}

private func thumbnail(id: Int, title: String, isNsfw: Bool = false) -> EntityThumbnail {
    EntityThumbnail(
        id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", id))!,
        kind: .video,
        title: title,
        isNsfw: isNsfw
    )
}

private func queryDictionary(_ items: [URLQueryItem]) -> [String: String] {
    Dictionary(
        uniqueKeysWithValues: items.compactMap { item in
            item.value.map { (item.name, $0) }
        })
}
