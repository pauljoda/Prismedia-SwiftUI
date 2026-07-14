import XCTest

@testable import PrismediaCore

@MainActor
final class EntityImageViewerSessionTests: XCTestCase {
    func testRouteSessionKeepsTheLastSelectedImage() {
        let first = image(id: 1)
        let second = image(id: 2)
        let session = EntityImageViewerSession(
            selected: first,
            sequence: EntityMediaSequence(items: [first, second])
        )

        session.select(second.id)

        XCTAssertEqual(session.currentEntityID, second.id)
        XCTAssertEqual(session.currentItem, second)
    }

    func testContinuationWaitsUntilTheSelectionIsNearTheTail() async {
        let items = (1...5).map(image)
        let loader = EntityMediaSequenceLoaderStub(results: [
            .success(EntityMediaSequencePage(items: [image(id: 6)], nextCursor: nil))
        ])
        let session = makeSession(items: items, cursor: "page-2", loader: loader)

        session.select(items[0].id)
        await session.loadNextPageIfNeeded()
        XCTAssertEqual(loader.requests.count, 0)

        session.select(items[2].id)
        await session.loadNextPageIfNeeded()

        XCTAssertEqual(loader.requests.map(\.cursor), ["page-2"])
        XCTAssertEqual(session.sequence.items, items + [image(id: 6)])
    }

    func testSequenceExpansionAppendsOnlyUniqueImagesInOrder() async {
        let first = image(id: 1)
        let second = image(id: 2)
        let third = image(id: 3)
        let nonImage = EntityThumbnail(id: testID(9), kind: .video, title: "Video 9")
        let loader = EntityMediaSequenceLoaderStub(results: [
            .success(
                EntityMediaSequencePage(
                    items: [second, nonImage, third, third],
                    nextCursor: "page-3"
                )
            )
        ])
        let session = makeSession(items: [first, second], cursor: "page-2", loader: loader)

        session.select(second.id)
        await session.loadNextPageIfNeeded()

        XCTAssertEqual(session.sequence.items, [first, second, third])
        XCTAssertEqual(session.sequence.nextPageRequest?.cursor, "page-3")
        XCTAssertEqual(
            session.sequence.nextPageRequest?.existingItemIDs,
            Set([first.id, second.id, third.id, nonImage.id])
        )
    }

    func testRepeatedTailSignalsCoalesceWhileARequestIsInFlight() async {
        let first = image(id: 1)
        let second = image(id: 2)
        let loader = SuspendedEntityMediaSequenceLoader()
        let session = makeSession(items: [first, second], cursor: "page-2", loader: loader)
        session.select(second.id)

        let firstSignal = Task { await session.loadNextPageIfNeeded() }
        await loader.waitUntilRequested()
        let repeatedSignal = Task { await session.loadNextPageIfNeeded() }
        await Task.yield()

        XCTAssertEqual(loader.requests.count, 1)
        XCTAssertTrue(session.isLoadingNextPage)

        loader.resume(with: EntityMediaSequencePage(items: [image(id: 3)], nextCursor: nil))
        await firstSignal.value
        await repeatedSignal.value

        XCTAssertFalse(session.isLoadingNextPage)
        XCTAssertEqual(loader.requests.count, 1)
    }

    func testCancelledSelectionTaskDoesNotStrandAnInFlightContinuation() async {
        let first = image(id: 1)
        let second = image(id: 2)
        let third = image(id: 3)
        let loader = SuspendedEntityMediaSequenceLoader()
        let session = makeSession(items: [first, second], cursor: "page-2", loader: loader)
        session.select(second.id)

        let firstSelectionTask = Task { await session.loadNextPageIfNeeded() }
        await loader.waitUntilRequested()
        firstSelectionTask.cancel()
        session.select(first.id)
        let replacementSelectionTask = Task { await session.loadNextPageIfNeeded() }
        await Task.yield()

        XCTAssertEqual(loader.requests.count, 1)
        XCTAssertTrue(session.isLoadingNextPage)

        loader.resume(with: EntityMediaSequencePage(items: [third], nextCursor: nil))
        await firstSelectionTask.value
        await replacementSelectionTask.value

        XCTAssertEqual(loader.requests.count, 1)
        XCTAssertEqual(session.sequence.items, [first, second, third])
        XCTAssertNil(session.paginationErrorMessage)
    }

    func testNewTailLoadsTheNextCursor() async {
        let first = image(id: 1)
        let second = image(id: 2)
        let third = image(id: 3)
        let fourth = image(id: 4)
        let loader = EntityMediaSequenceLoaderStub(results: [
            .success(EntityMediaSequencePage(items: [third], nextCursor: "page-3")),
            .success(EntityMediaSequencePage(items: [fourth], nextCursor: nil)),
        ])
        let session = makeSession(items: [first, second], cursor: "page-2", loader: loader)

        session.select(second.id)
        await session.loadNextPageIfNeeded()
        session.select(third.id)
        await session.loadNextPageIfNeeded()

        XCTAssertEqual(loader.requests.map(\.cursor), ["page-2", "page-3"])
        XCTAssertEqual(session.sequence.items, [first, second, third, fourth])
        XCTAssertNil(session.sequence.nextPageRequest)
    }

    func testFailedContinuationCanRetryTheSameCursor() async {
        let first = image(id: 1)
        let second = image(id: 2)
        let third = image(id: 3)
        let loader = EntityMediaSequenceLoaderStub(results: [
            .failure(.unavailable),
            .success(EntityMediaSequencePage(items: [third], nextCursor: nil)),
        ])
        let session = makeSession(items: [first, second], cursor: "page-2", loader: loader)
        session.select(second.id)

        await session.loadNextPageIfNeeded()
        XCTAssertNotNil(session.paginationErrorMessage)
        await session.loadNextPageIfNeeded()

        XCTAssertEqual(loader.requests.map(\.cursor), ["page-2", "page-2"])
        XCTAssertNil(session.paginationErrorMessage)
        XCTAssertEqual(session.sequence.items, [first, second, third])
    }

    func testMissingCursorDoesNotCallTheLoader() async {
        let first = image(id: 1)
        let loader = EntityMediaSequenceLoaderStub(results: [
            .success(EntityMediaSequencePage(items: [image(id: 2)], nextCursor: nil))
        ])
        let session = EntityImageViewerSession(
            selected: first,
            sequence: EntityMediaSequence(items: [first]),
            sequenceLoader: loader
        )

        await session.loadNextPageIfNeeded()

        XCTAssertTrue(loader.requests.isEmpty)
    }

    private func makeSession(
        items: [EntityThumbnail],
        cursor: String,
        loader: any EntityMediaSequenceLoading
    ) -> EntityImageViewerSession {
        let continuation = EntityMediaSequenceContinuation(
            query: EntityListQuery(kind: .image, sort: "random", seed: 42),
            pageSize: 48,
            search: "portrait",
            cursor: cursor,
            existingItemIDs: Set(items.map(\.id)),
            excludedNsfwIDs: []
        )
        return EntityImageViewerSession(
            selected: items[0],
            sequence: EntityMediaSequence(items: items, continuation: continuation),
            sequenceLoader: loader
        )
    }
}

@MainActor
final class EntityGridMediaSequenceLoaderTests: XCTestCase {
    func testGridContinuationKeepsTheEffectiveQuerySeedAndSafetyState() async throws {
        let first = image(id: 1)
        let second = image(id: 2)
        let excluded = testID(99)
        let configuration = EntityGridConfiguration(
            title: "Images",
            query: EntityListQuery(kind: .image, favorite: true)
        )
        var snapshot = EntityGridSnapshot(configuration: configuration)
        var controls = snapshot.controls
        controls.sort = .random
        controls.randomSeed = 867_5309
        snapshot.setControls(controls)
        _ = snapshot.setSearch("  portrait  ")
        let firstRequest = snapshot.beginFirstPage(
            configuration: configuration,
            pageSize: 96,
            preservingContent: false
        )
        snapshot.receiveFirstPage(
            EntityGridPage(
                items: [first],
                nextCursor: "page-2",
                totalCount: 3,
                excludedNsfwIDs: [excluded]
            ),
            for: firstRequest
        )
        let sequence = snapshot.mediaSequence(configuration: configuration, pageSize: 96)
        let gridLoader = EntityGridContinuationLoaderStub(
            response: EntityListResponse(items: [first, second], nextCursor: nil, totalCount: 3)
        )
        let loader = EntityGridMediaSequenceLoader(loader: gridLoader)

        _ = try await loader.loadNextPage(XCTUnwrap(sequence.nextPageRequest))

        let request = try XCTUnwrap(gridLoader.requests.first)
        XCTAssertEqual(request.query.kind, .image)
        XCTAssertEqual(request.query.sort, "random")
        XCTAssertEqual(request.query.seed, 867_5309)
        XCTAssertEqual(request.query.favorite, true)
        XCTAssertEqual(request.limit, 96)
        XCTAssertEqual(request.search, "portrait")
        XCTAssertEqual(request.cursor, "page-2")
        XCTAssertEqual(sequence.nextPageRequest?.existingItemIDs, Set([first.id]))
        XCTAssertEqual(sequence.nextPageRequest?.excludedNsfwIDs, Set([excluded]))
    }
}

@MainActor
private final class EntityMediaSequenceLoaderStub: EntityMediaSequenceLoading {
    private var results: [Result<EntityMediaSequencePage, EntityMediaSequenceTestError>]
    private(set) var requests: [EntityMediaSequencePageRequest] = []

    init(results: [Result<EntityMediaSequencePage, EntityMediaSequenceTestError>]) {
        self.results = results
    }

    func loadNextPage(_ request: EntityMediaSequencePageRequest) async throws -> EntityMediaSequencePage {
        requests.append(request)
        guard !results.isEmpty else { throw EntityMediaSequenceTestError.unavailable }
        return try results.removeFirst().get()
    }
}

@MainActor
private final class SuspendedEntityMediaSequenceLoader: EntityMediaSequenceLoading {
    private(set) var requests: [EntityMediaSequencePageRequest] = []
    private var responseContinuation: CheckedContinuation<EntityMediaSequencePage, Error>?

    func loadNextPage(_ request: EntityMediaSequencePageRequest) async throws -> EntityMediaSequencePage {
        requests.append(request)
        let page = try await withCheckedThrowingContinuation { responseContinuation = $0 }
        try Task.checkCancellation()
        return page
    }

    func waitUntilRequested() async {
        while requests.isEmpty { await Task.yield() }
    }

    func resume(with page: EntityMediaSequencePage) {
        responseContinuation?.resume(returning: page)
        responseContinuation = nil
    }
}

@MainActor
private final class EntityGridContinuationLoaderStub: EntityGridLoading {
    struct Request {
        let query: EntityListQuery
        let limit: Int
        let search: String?
        let cursor: String?
    }

    let allowsNsfwContent = false
    private let response: EntityListResponse
    private(set) var requests: [Request] = []

    init(response: EntityListResponse) {
        self.response = response
    }

    func load(
        query: EntityListQuery,
        limit: Int,
        search: String?,
        cursor: String?
    ) async throws -> EntityListResponse {
        requests.append(Request(query: query, limit: limit, search: search, cursor: cursor))
        return response
    }
}

private enum EntityMediaSequenceTestError: Error {
    case unavailable
}

private func image(id: Int) -> EntityThumbnail {
    EntityThumbnail(id: testID(id), kind: .image, title: "Image \(id)")
}

private func testID(_ value: Int) -> UUID {
    UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", value))!
}
