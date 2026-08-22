import XCTest

@testable import PrismediaCore

@MainActor
final class BookReaderUseCaseTests: XCTestCase {
    func testOpeningReaderRecordsOneAccessPerPresentation() async throws {
        let bookID = UUID()
        let service = OrderedProgressService(values: [:])
        let writer = BookReaderProgressWriter(service: service)

        writer.beginActivity(bookID: bookID)
        writer.beginActivity(bookID: bookID)
        await writer.flush()

        let accesses = await service.recordedAccesses()
        XCTAssertEqual(accesses.map(\.id), [bookID])
        XCTAssertFalse(try XCTUnwrap(accesses.first?.sessionID).isEmpty)
    }

    func testRapidPageTurnsCoalesceToTheLatestCompletedPosition() async throws {
        let installmentID = UUID(uuidString: "10000000-0000-0000-0000-000000000001")!
        let installment = EntityDetail(
            id: installmentID,
            kind: .comicInstallment,
            title: "Chapter",
            parentEntityID: nil,
            sortOrder: 0,
            hasSourceMedia: true,
            capabilities: [.pageSequence(.init(
                pageCount: 3,
                direction: .leftToRight,
                defaultMode: .paged,
                coverOrdinal: 0
            ))],
            childrenByKind: [],
            relationships: []
        )
        let source = EntityReaderManifest(
            entityID: installmentID,
            direction: .leftToRight,
            defaultMode: .paged,
            coverOrdinal: 0,
            pages: (0..<3).map { EntityReaderManifestPage(ordinal: $0, mimeType: "image/jpeg") }
        )
        let service = OrderedProgressService(values: [installmentID: installment], manifests: [installmentID: source])
        let useCase = BookReaderUseCase(selected: installment, command: .read, service: service)
        let manifest = try await useCase.loadManifest()
        let writer = BookReaderProgressWriter(service: service)

        writer.queue(
            bookID: manifest.bookID,
            request: try XCTUnwrap(useCase.progressRequest(in: manifest, index: 1, mode: .paged))
        )
        writer.queue(
            bookID: manifest.bookID,
            request: try XCTUnwrap(useCase.progressRequest(in: manifest, index: 2, mode: .paged))
        )
        await writer.flush()

        let completed = await service.completedRequests()
        XCTAssertEqual(completed.map(\.index), [2])
        XCTAssertEqual(completed[0].completed, true)
    }

    func testPageStoreRetainsOnlyTheCurrentWarmWindow() async throws {
        let pages = (0..<4).map { ordinal in
            readerPage(entityID: UUID(), ordinal: ordinal)
        }
        let service = PageDataService(data: Self.validPNG)
        let store = BookReaderPageCache(service: service)

        store.retainOnly(Set(pages.prefix(3).map(\.id)))
        for page in pages.prefix(3) { _ = try await store.data(for: page) }
        XCTAssertEqual(Set(store.images.keys), Set(pages.prefix(3).map(\.id)))

        store.retainOnly([pages[2].id, pages[3].id])
        _ = try await store.data(for: pages[3])
        XCTAssertEqual(Set(store.images.keys), [pages[2].id, pages[3].id])
    }

    func testPageStoreSurfacesDecodeFailureAndAllowsRetry() async {
        let page = readerPage(entityID: UUID())
        let service = PageDataService(data: Data("not an image".utf8))
        let store = BookReaderPageCache(service: service)
        store.retainOnly([page.id])

        await xctAssertThrowsErrorAsync { _ = try await store.data(for: page) }
        await xctAssertThrowsErrorAsync { _ = try await store.data(for: page) }
        XCTAssertNil(store.images[page.id])
        let loadCount = await service.loadCount()
        XCTAssertEqual(loadCount, 2)
    }

    func testConcurrentPageRequestsShareTransportAndDecodeAtTheBoundedSize() async throws {
        let page = readerPage(entityID: UUID())
        let service = PageDataService(data: Self.validPNG)
        let decoder = PageImageDecoderSpy()
        let store = BookReaderPageCache(service: service, decoder: decoder.decode)
        store.retainOnly([page.id])

        async let first = store.data(for: page)
        async let second = store.data(for: page)
        _ = try await (first, second)

        let loadCount = await service.loadCount()
        XCTAssertEqual(loadCount, 1)
        XCTAssertEqual(decoder.callCount, 1)
        XCTAssertEqual(decoder.maximumPixelSizes, [4_096])
    }

    func testComicPrewarmingLimitsConcurrentPageLoads() async {
        let pageCount = 7
        let service = ConcurrentPageDataService(data: Self.validPNG)
        let store = BookReaderPageCache(service: service)
        let manifest = makeManifest(pageCount: pageCount)

        await ComicReaderPagePreloader(cache: store).prefetch(
            around: 3,
            manifest: manifest,
            options: ComicReaderOptions()
        )

        let metrics = await service.metrics()
        XCTAssertEqual(metrics.requestCount, 5)
        XCTAssertLessThanOrEqual(metrics.maximumConcurrentRequests, 2)
    }

    private func makeManifest(pageCount: Int) -> BookReaderManifest {
        let installmentID = UUID()
        let installment = EntityDetail(
            id: installmentID,
            kind: .comicInstallment,
            title: "Chapter",
            parentEntityID: nil,
            sortOrder: 0,
            hasSourceMedia: true,
            capabilities: [],
            childrenByKind: [],
            relationships: []
        )
        let pages = (0..<pageCount).map {
            BookReaderPage(entityID: installmentID, page: .init(ordinal: $0, mimeType: "image/jpeg"))
        }
        return BookReaderManifest(
            bookID: installmentID,
            title: "Comic",
            chapters: [BookReaderChapter(detail: installment, readerPages: pages, sequenceIndex: 0)],
            nextChapter: nil,
            progress: nil,
            initialIndex: 0,
            readerMode: .paged
        )
    }

    private func readerPage(entityID: UUID, ordinal: Int = 0) -> BookReaderPage {
        BookReaderPage(entityID: entityID, page: .init(ordinal: ordinal, mimeType: "image/png"))
    }

    private static let validPNG = Data(
        base64Encoded:
            "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScL+WQAAAABJRU5ErkJggg=="
    )!
}

private actor OrderedProgressService: BookReaderServicing {
    let values: [UUID: EntityDetail]
    let manifests: [UUID: EntityReaderManifest]
    private var completed: [EntityProgressUpdateRequest] = []
    private var accesses: [(id: UUID, sessionID: String)] = []

    init(values: [UUID: EntityDetail], manifests: [UUID: EntityReaderManifest] = [:]) {
        self.values = values
        self.manifests = manifests
    }

    func loadEntity(id: UUID) async throws -> EntityDetail {
        guard let value = values[id] else { throw OrderedProgressError.missing }
        return value
    }

    func loadEntityReaderManifest(id: UUID) async throws -> EntityReaderManifest {
        guard let manifest = manifests[id] else { throw OrderedProgressError.missing }
        return manifest
    }

    func loadEntityReaderPageData(id: UUID, ordinal: Int) async throws -> Data { Data() }

    func recordReadingAccess(id: UUID, sessionID: String) async throws {
        accesses.append((id, sessionID))
    }

    func updateReadingProgress(id: UUID, request: EntityProgressUpdateRequest) async throws {
        if request.index == 1 { try await Task.sleep(for: .milliseconds(80)) }
        completed.append(request)
    }

    func completedRequests() -> [EntityProgressUpdateRequest] { completed }
    func recordedAccesses() -> [(id: UUID, sessionID: String)] { accesses }
}

private enum OrderedProgressError: Error {
    case missing
}

private actor PageDataService: BookReaderServicing {
    let data: Data
    private var count = 0

    init(data: Data) { self.data = data }

    func loadEntity(id: UUID) async throws -> EntityDetail { throw OrderedProgressError.missing }

    func loadEntityReaderPageData(id: UUID, ordinal: Int) async throws -> Data {
        count += 1
        return data
    }

    func updateReadingProgress(id: UUID, request: EntityProgressUpdateRequest) async throws {}

    func loadCount() -> Int { count }
}

private actor ConcurrentPageDataService: BookReaderServicing {
    private let data: Data
    private var activeRequests = 0
    private var maximumConcurrentRequests = 0
    private var requestCount = 0

    init(data: Data) {
        self.data = data
    }

    func loadEntity(id: UUID) async throws -> EntityDetail {
        throw OrderedProgressError.missing
    }

    func loadEntityReaderPageData(id: UUID, ordinal: Int) async throws -> Data {
        requestCount += 1
        activeRequests += 1
        maximumConcurrentRequests = max(maximumConcurrentRequests, activeRequests)
        defer { activeRequests -= 1 }
        try await Task.sleep(for: .milliseconds(30))
        return data
    }

    func updateReadingProgress(id: UUID, request: EntityProgressUpdateRequest) async throws {}

    func metrics() -> (requestCount: Int, maximumConcurrentRequests: Int) {
        (requestCount, maximumConcurrentRequests)
    }
}

private final class PageImageDecoderSpy: @unchecked Sendable {
    private let lock = NSLock()
    private var calls = 0
    private var sizes: [Int] = []

    var callCount: Int {
        lock.withLock { calls }
    }

    var maximumPixelSizes: [Int] {
        lock.withLock { sizes }
    }

    func decode(data: Data, maximumPixelSize: Int) -> PlatformReaderImage? {
        lock.withLock {
            calls += 1
            sizes.append(maximumPixelSize)
        }
        return EntityImageStillDecoder.decode(
            data: data,
            maximumPixelSize: maximumPixelSize
        )
    }
}

@MainActor
private func xctAssertThrowsErrorAsync(
    _ expression: () async throws -> Void,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        try await expression()
        XCTFail("Expected expression to throw", file: file, line: line)
    } catch {}
}
