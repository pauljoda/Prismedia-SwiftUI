import Foundation
import XCTest

@testable import PrismediaCore

final class EntityMediaContentLoaderTests: XCTestCase {
    func testPrepareLoadsOnlyTheActiveImageAndItsImmediateNeighbors() async throws {
        let items = makeItems(count: 5)
        let service = ImageViewerLoadingSpy(details: makeDetails(for: items))
        let loader = EntityMediaContentLoader(
            detailLoader: service,
            sourceLoader: service,
            retainedItems: EntityMediaSequence(items: items).preloadItems(around: items[2].id)
        )

        await loader.prepare(
            activeEntityID: items[2].id,
            sequence: EntityMediaSequence(items: items)
        )

        let expected = Set([items[1].id, items[2].id, items[3].id])
        let detailIDs = await service.requestedDetailIDs()
        let sourceIDs = await service.requestedSourceIDs()
        XCTAssertEqual(detailIDs, expected)
        XCTAssertEqual(sourceIDs, expected)
    }

    func testVisiblePageAndPreloaderCoalesceActiveDetailAndSourceRequests() async throws {
        let items = makeItems(count: 3)
        let service = ImageViewerLoadingSpy(
            details: makeDetails(for: items),
            delay: .milliseconds(30)
        )
        let sequence = EntityMediaSequence(items: items)
        let loader = EntityMediaContentLoader(
            detailLoader: service,
            sourceLoader: service,
            retainedItems: sequence.preloadItems(around: items[1].id)
        )

        async let prepared: Void = loader.prepare(
            activeEntityID: items[1].id,
            sequence: sequence
        )
        async let detail = loader.loadDetail(id: items[1].id)
        async let source = loader.loadSourceData(id: items[1].id)
        _ = try await (prepared, detail, source)

        let detailCount = await service.detailRequestCount(for: items[1].id)
        let sourceCount = await service.sourceRequestCount(for: items[1].id)
        XCTAssertEqual(detailCount, 1)
        XCTAssertEqual(sourceCount, 1)
    }

    func testPreparingANewWindowCancelsAStaleNonOverlappingRequest() async throws {
        let items = makeItems(count: 6)
        let service = ImageViewerLoadingSpy(
            details: makeDetails(for: items),
            delay: .milliseconds(250)
        )
        let sequence = EntityMediaSequence(items: items)
        let loader = EntityMediaContentLoader(
            detailLoader: service,
            sourceLoader: service,
            retainedItems: sequence.preloadItems(around: items[1].id)
        )

        let stalePreparation = Task {
            await loader.prepare(activeEntityID: items[1].id, sequence: sequence)
        }
        try await waitUntil {
            await service.detailRequestCount(for: items[1].id) == 1
        }

        await loader.prepare(activeEntityID: items[5].id, sequence: sequence)
        await stalePreparation.value

        let staleRequestWasCancelled = await service.wasDetailRequestCancelled(for: items[1].id)
        let staleNeighborRequestCount = await service.detailRequestCount(for: items[2].id)
        let requestedDetailIDs = await service.requestedDetailIDs()
        XCTAssertTrue(staleRequestWasCancelled)
        XCTAssertEqual(staleNeighborRequestCount, 0)
        XCTAssertEqual(requestedDetailIDs, Set([items[1].id, items[4].id, items[5].id]))
    }

    func testCancellingAFeedSourceLoadStopsThePendingRequest() async throws {
        let item = makeItems(count: 1)[0]
        let service = ImageViewerLoadingSpy(
            details: makeDetails(for: [item]),
            delay: .seconds(1)
        )
        let loader = EntityMediaContentLoader(
            detailLoader: service,
            sourceLoader: service,
            retainedItems: [item]
        )

        let sourceLoad = Task { try await loader.loadSourceData(id: item.id) }
        try await waitUntil {
            await service.sourceRequestCount(for: item.id) == 1
        }

        await loader.cancelSourceLoad(id: item.id)

        do {
            _ = try await sourceLoad.value
            XCTFail("Expected the offscreen source request to be cancelled")
        } catch is CancellationError {
            let wasCancelled = await service.wasSourceRequestCancelled(for: item.id)
            XCTAssertTrue(wasCancelled)
        }
    }

    func testReenteredFeedConsumerSurvivesLateCancellationFromRecycledRow() async throws {
        let item = makeItems(count: 1)[0]
        let service = ImageViewerLoadingSpy(
            details: makeDetails(for: [item]),
            delay: .milliseconds(100)
        )
        let loader = EntityMediaContentLoader(
            detailLoader: service,
            sourceLoader: service,
            retainedItems: [item]
        )
        let recycledConsumerID = UUID()
        let visibleConsumerID = UUID()

        let recycledLoad = Task {
            try await loader.loadSourceData(id: item.id, consumerID: recycledConsumerID)
        }
        try await waitUntil {
            await service.sourceRequestCount(for: item.id) == 1
        }
        let visibleLoad = Task {
            try await loader.loadSourceData(id: item.id, consumerID: visibleConsumerID)
        }

        await loader.cancelSourceLoad(id: item.id, consumerID: recycledConsumerID)

        let data = try await visibleLoad.value
        let sourceRequestCount = await service.sourceRequestCount(for: item.id)
        XCTAssertFalse(data.isEmpty)
        XCTAssertLessThanOrEqual(sourceRequestCount, 2)
        _ = try? await recycledLoad.value
    }

    func testSourceCacheEvictsLeastRecentlyUsedBytesWhileRetainingTheFullFeed() async throws {
        let items = makeItems(count: 3)
        let service = ImageViewerLoadingSpy(details: makeDetails(for: items))
        let sourceByteCount = items[0].id.uuidString.utf8.count
        let loader = EntityMediaContentLoader(
            detailLoader: service,
            sourceLoader: service,
            retainedItems: items,
            sourceCacheByteLimit: sourceByteCount * 2
        )

        _ = try await loader.loadSourceData(id: items[0].id)
        _ = try await loader.loadSourceData(id: items[1].id)
        _ = try await loader.loadSourceData(id: items[0].id)
        _ = try await loader.loadSourceData(id: items[2].id)
        _ = try await loader.loadSourceData(id: items[1].id)

        let firstCount = await service.sourceRequestCount(for: items[0].id)
        let secondCount = await service.sourceRequestCount(for: items[1].id)
        let thirdCount = await service.sourceRequestCount(for: items[2].id)
        XCTAssertEqual(firstCount, 1)
        XCTAssertEqual(secondCount, 2)
        XCTAssertEqual(thirdCount, 1)
    }

    private func makeItems(count: Int) -> [EntityThumbnail] {
        (0..<count).map { index in
            EntityThumbnail(
                id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", index + 1))!,
                kind: .image,
                title: "Image \(index + 1)",
                hasSourceMedia: true
            )
        }
    }

    private func makeDetails(for items: [EntityThumbnail]) -> [UUID: EntityDetail] {
        Dictionary(
            uniqueKeysWithValues: items.map { item in
                (
                    item.id,
                    EntityDetail(
                        id: item.id,
                        kind: .image,
                        title: item.title,
                        parentEntityID: nil,
                        sortOrder: nil,
                        hasSourceMedia: true,
                        capabilities: [
                            .files(
                                EntityItemsCapability(
                                    items: [
                                        EntityFile(
                                            role: "source",
                                            path: "/library/\(item.id.uuidString).png",
                                            mimeType: "image/png"
                                        )
                                    ]
                                )
                            )
                        ],
                        childrenByKind: [],
                        relationships: []
                    )
                )
            })
    }

    private func waitUntil(
        timeout: Duration = .seconds(1),
        condition: @escaping @Sendable () async -> Bool
    ) async throws {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)
        while !(await condition()) {
            guard clock.now < deadline else {
                XCTFail("Timed out waiting for the asynchronous condition")
                return
            }
            try await Task.sleep(for: .milliseconds(5))
        }
    }
}

private actor ImageViewerLoadingSpy: EntityDetailLoading, EntityImageSourceLoading {
    private let details: [UUID: EntityDetail]
    private let delay: Duration
    private var detailCounts: [UUID: Int] = [:]
    private var sourceCounts: [UUID: Int] = [:]
    private var cancelledDetailIDs = Set<UUID>()
    private var cancelledSourceIDs = Set<UUID>()

    init(details: [UUID: EntityDetail], delay: Duration = .zero) {
        self.details = details
        self.delay = delay
    }

    func loadEntity(id: UUID) async throws -> EntityDetail {
        detailCounts[id, default: 0] += 1
        do {
            if delay > .zero { try await Task.sleep(for: delay) }
        } catch is CancellationError {
            cancelledDetailIDs.insert(id)
            throw CancellationError()
        }
        guard let detail = details[id] else { throw URLError(.fileDoesNotExist) }
        return detail
    }

    func loadEntitySourceData(id: UUID) async throws -> Data {
        sourceCounts[id, default: 0] += 1
        do {
            if delay > .zero { try await Task.sleep(for: delay) }
        } catch is CancellationError {
            cancelledSourceIDs.insert(id)
            throw CancellationError()
        }
        return Data(id.uuidString.utf8)
    }

    func requestedDetailIDs() -> Set<UUID> { Set(detailCounts.keys) }
    func requestedSourceIDs() -> Set<UUID> { Set(sourceCounts.keys) }
    func detailRequestCount(for id: UUID) -> Int { detailCounts[id, default: 0] }
    func sourceRequestCount(for id: UUID) -> Int { sourceCounts[id, default: 0] }
    func wasDetailRequestCancelled(for id: UUID) -> Bool { cancelledDetailIDs.contains(id) }
    func wasSourceRequestCancelled(for id: UUID) -> Bool { cancelledSourceIDs.contains(id) }
}
