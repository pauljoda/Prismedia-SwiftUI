import XCTest

@testable import PrismediaCore

@MainActor
final class BookReaderUseCaseTests: XCTestCase {
    func testRapidPageTurnsCoalesceToTheLatestCompletedPosition() async throws {
        let bookID = UUID(uuidString: "10000000-0000-0000-0000-000000000001")!
        let chapterID = UUID(uuidString: "20000000-0000-0000-0000-000000000001")!
        let pages = (0..<3).map { index in
            EntityThumbnail(
                id: UUID(uuidString: "30000000-0000-0000-0000-00000000000\(index + 1)")!,
                kind: .bookPage,
                title: "Page \(index + 1)",
                parentEntityID: chapterID,
                sortOrder: index
            )
        }
        let book = EntityDetail(
            id: bookID,
            kind: .book,
            title: "Book",
            parentEntityID: nil,
            sortOrder: nil,
            bookFormat: .imageArchive,
            hasSourceMedia: true,
            capabilities: [],
            childrenByKind: [
                EntityGroup(
                    kind: .bookChapter,
                    label: "Chapters",
                    entities: [
                        EntityThumbnail(
                            id: chapterID, kind: .bookChapter, title: "Chapter", parentEntityID: bookID, sortOrder: 0)
                    ],
                    code: nil
                )
            ],
            relationships: []
        )
        let chapter = EntityDetail(
            id: chapterID,
            kind: .bookChapter,
            title: "Chapter",
            parentEntityID: bookID,
            sortOrder: 0,
            hasSourceMedia: false,
            capabilities: [],
            childrenByKind: [EntityGroup(kind: .bookPage, label: "Pages", entities: pages, code: nil)],
            relationships: []
        )
        let service = OrderedProgressService(values: [bookID: book, chapterID: chapter])
        let useCase = BookReaderUseCase(selected: book, command: .read, service: service)
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
        let ids = (0..<4).map { _ in UUID() }
        let service = PageDataService(data: Self.validPNG)
        let store = BookReaderPageCache(service: service)

        store.retainOnly(Set(ids.prefix(3)))
        for id in ids.prefix(3) { _ = try await store.data(for: id) }
        XCTAssertEqual(Set(store.images.keys), Set(ids.prefix(3)))

        store.retainOnly([ids[2], ids[3]])
        _ = try await store.data(for: ids[3])
        XCTAssertEqual(Set(store.images.keys), [ids[2], ids[3]])
    }

    func testPageStoreSurfacesDecodeFailureAndAllowsRetry() async {
        let id = UUID()
        let service = PageDataService(data: Data("not an image".utf8))
        let store = BookReaderPageCache(service: service)
        store.retainOnly([id])

        await xctAssertThrowsErrorAsync { _ = try await store.data(for: id) }
        await xctAssertThrowsErrorAsync { _ = try await store.data(for: id) }
        XCTAssertNil(store.images[id])
        let loadCount = await service.loadCount()
        XCTAssertEqual(loadCount, 2)
    }

    func testConcurrentPageRequestsShareTransportAndDecodeAtTheBoundedSize() async throws {
        let id = UUID()
        let service = PageDataService(data: Self.validPNG)
        let decoder = PageImageDecoderSpy()
        let store = BookReaderPageCache(service: service, decoder: decoder.decode)
        store.retainOnly([id])

        async let first = store.data(for: id)
        async let second = store.data(for: id)
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
        let bookID = UUID()
        let chapterID = UUID()
        let chapter = EntityDetail(
            id: chapterID,
            kind: .bookChapter,
            title: "Chapter",
            parentEntityID: bookID,
            sortOrder: 0,
            hasSourceMedia: false,
            capabilities: [],
            childrenByKind: [],
            relationships: []
        )
        let pages = (0..<pageCount).map { index in
            EntityThumbnail(
                id: UUID(),
                kind: .bookPage,
                title: "Page \(index + 1)",
                parentEntityID: chapterID,
                sortOrder: index
            )
        }
        return BookReaderManifest(
            bookID: bookID,
            title: "Book",
            chapters: [BookReaderChapter(detail: chapter, pages: pages, sequenceIndex: 0)],
            nextChapter: nil,
            progress: nil,
            initialIndex: 0,
            readerMode: .paged
        )
    }

    private static let validPNG = Data(
        base64Encoded:
            "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScL+WQAAAABJRU5ErkJggg=="
    )!
}

private actor OrderedProgressService: BookReaderServicing {
    let values: [UUID: EntityDetail]
    private var completed: [EntityProgressUpdateRequest] = []

    init(values: [UUID: EntityDetail]) {
        self.values = values
    }

    func loadEntity(id: UUID) async throws -> EntityDetail {
        guard let value = values[id] else { throw OrderedProgressError.missing }
        return value
    }

    func loadPageData(id: UUID) async throws -> Data { Data() }

    func updateReadingProgress(id: UUID, request: EntityProgressUpdateRequest) async throws {
        if request.index == 1 { try await Task.sleep(for: .milliseconds(80)) }
        completed.append(request)
    }

    func completedRequests() -> [EntityProgressUpdateRequest] { completed }
}

private enum OrderedProgressError: Error {
    case missing
}

private actor PageDataService: BookReaderServicing {
    let data: Data
    private var count = 0

    init(data: Data) { self.data = data }

    func loadEntity(id: UUID) async throws -> EntityDetail { throw OrderedProgressError.missing }

    func loadPageData(id: UUID) async throws -> Data {
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

    func loadPageData(id: UUID) async throws -> Data {
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
