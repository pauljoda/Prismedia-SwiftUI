import Foundation
import XCTest

@testable import PrismediaCore

@MainActor
final class EntityDetailReadingTests: XCTestCase {
    private let bookID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    private let chapterID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    private let pageID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!

    func testMissingBookMediaDoesNotOfferReadingEvenWithSavedProgress() async {
        let book = EntityDetail(
            id: bookID, kind: .book, title: "Missing book",
            parentEntityID: nil, sortOrder: nil, hasSourceMedia: false,
            capabilities: [
                .bookMetadata(.init(bookType: "book", format: .epub)),
                .progress(makeSingleFileProgress(unit: .cfi, index: 100, total: 10000, mode: .paged, location: nil))
            ], childrenByKind: [], relationships: []
        )
        let service = EntityDetailReadingService(reader: ReadingServiceStub(details: [bookID: book]))
        XCTAssertFalse(EntityReadingPolicy.supportsReading(book))
        let outcome = await service.load(detail: book)
        guard case .unavailable = outcome else {
            return XCTFail("Saved progress must not expose a missing document.")
        }
    }

    func testEmptyPageSequenceDoesNotOfferReading() {
        let book = EntityDetail(
            id: bookID, kind: .book, title: "Pending comic",
            parentEntityID: nil, sortOrder: nil, hasSourceMedia: false,
            capabilities: [.pageSequence(.init(pageCount: 0, direction: .leftToRight, defaultMode: .paged, coverOrdinal: nil))],
            childrenByKind: [], relationships: []
        )
        XCTAssertFalse(EntityReadingPolicy.supportsReading(book))
    }

    func testNewerReadingRequestRejectsAnOlderResponse() throws {
        var state = EntityDetailReadingState()
        let older = state.beginLoad(entityID: bookID)
        let newerBookID = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
        let newer = state.beginLoad(entityID: newerBookID)
        let staleManifest = makeManifest(bookID: bookID, title: "Stale")
        let currentManifest = makeManifest(bookID: newerBookID, title: "Current")

        state.finishLoad(.content(currentManifest), request: newer)
        state.finishLoad(.content(staleManifest), request: older)

        XCTAssertEqual(state.phase, .content(currentManifest))
    }

    func testReadingMutationRejectsOverlap() throws {
        let manifest = makeManifest(bookID: bookID, title: "Current")
        var state = EntityDetailReadingState()
        let load = state.beginLoad(entityID: bookID)
        state.finishLoad(.content(manifest), request: load)

        let firstMutation = state.beginMutation()
        let overlappingMutation = state.beginMutation()

        XCTAssertNotNil(firstMutation)
        XCTAssertNil(overlappingMutation)
        XCTAssertTrue(state.isMutating)
    }

    func testReadingMutationFailureKeepsContentAndSurfacesTheError() throws {
        let manifest = makeManifest(bookID: bookID, title: "Current")
        var state = EntityDetailReadingState()
        let load = state.beginLoad(entityID: bookID)
        state.finishLoad(.content(manifest), request: load)
        let mutation = try XCTUnwrap(state.beginMutation())

        state.finishMutation(
            .failure("The server is unavailable."),
            request: mutation
        )

        XCTAssertEqual(state.phase, .content(manifest))
        XCTAssertEqual(state.errorMessage, "The server is unavailable.")
        XCTAssertFalse(state.isMutating)
    }

    func testEPUBProgressLoadsAsSingleFileReadingContent() async throws {
        let progress = makeSingleFileProgress(
            unit: .cfi,
            index: 4_250,
            total: 10_000,
            mode: .scrolled,
            location: "epubcfi(/6/4!/4/2/2:14)"
        )
        let book = makeSingleFileBook(format: .epub, progress: progress)
        let service = EntityDetailReadingService(
            reader: ReadingServiceStub(details: [bookID: book])
        )

        let outcome = await service.load(detail: book)

        guard case .singleFile(let loaded) = outcome else {
            return XCTFail("Expected EPUB progress to load as single-file reading content.")
        }
        XCTAssertEqual(loaded, book)
    }

    func testEPUBStartOverUsesTheLatestSingleFileProgressContract() async throws {
        let progress = makeSingleFileProgress(
            unit: .cfi,
            index: 4_250,
            total: 10_000,
            mode: .scrolled,
            location: "epubcfi(/6/4!/4/2/2:14)"
        )
        let book = makeSingleFileBook(format: .epub, progress: progress)
        let staleBook = makeSingleFileBook(format: .epub, progress: nil)
        let reader = ReadingServiceStub(details: [bookID: book])
        let service = EntityDetailReadingService(reader: reader)

        _ = await service.startOver(detail: staleBook, readerMode: .paged)

        let updates = await reader.progressUpdatesSnapshot()
        let update = try XCTUnwrap(updates.first)
        XCTAssertEqual(update.id, bookID)
        XCTAssertEqual(update.request.currentEntityID, bookID)
        XCTAssertEqual(update.request.unit, .cfi)
        XCTAssertEqual(update.request.index, 0)
        XCTAssertEqual(update.request.total, 10_000)
        XCTAssertEqual(update.request.mode, .scrolled)
        XCTAssertNil(update.request.completed)
        XCTAssertTrue(update.request.reset)
        XCTAssertNil(update.request.location)
    }

    func testPDFStartOverPreservesPageCountAndScrollMode() async throws {
        let progress = makeSingleFileProgress(
            unit: .page,
            index: 12,
            total: 240,
            mode: .scrolled,
            location: nil
        )
        let book = makeSingleFileBook(format: .pdf, progress: progress)
        let reader = ReadingServiceStub(details: [bookID: book])
        let service = EntityDetailReadingService(reader: reader)

        _ = await service.startOver(detail: book, readerMode: .paged)

        let updates = await reader.progressUpdatesSnapshot()
        let request = try XCTUnwrap(updates.first?.request)
        XCTAssertEqual(request.currentEntityID, bookID)
        XCTAssertEqual(request.unit, .page)
        XCTAssertEqual(request.index, 0)
        XCTAssertEqual(request.total, 240)
        XCTAssertEqual(request.mode, .scrolled)
        XCTAssertTrue(request.reset)
        XCTAssertNil(request.location)
    }

    func testSingleFileCompletionTogglePreservesTheSavedCursor() async throws {
        let location = "epubcfi(/6/4!/4/2/2:14)"
        let progress = makeSingleFileProgress(
            unit: .cfi,
            index: 4_250,
            total: 10_000,
            mode: .scrolled,
            location: location
        )
        let book = makeSingleFileBook(format: .epub, progress: progress)
        let reader = ReadingServiceStub(details: [bookID: book])
        let service = EntityDetailReadingService(reader: reader)

        _ = await service.toggleCompletion(
            detail: book,
            manifest: singleFileManifest(book),
            status: .inProgress
        )

        let updates = await reader.progressUpdatesSnapshot()
        let request = try XCTUnwrap(updates.first?.request)
        XCTAssertEqual(request.currentEntityID, bookID)
        XCTAssertEqual(request.unit, .cfi)
        XCTAssertEqual(request.index, 4_250)
        XCTAssertEqual(request.total, 10_000)
        XCTAssertEqual(request.mode, .scrolled)
        XCTAssertEqual(request.completed, true)
        XCTAssertFalse(request.reset)
        XCTAssertEqual(request.location, location)
    }

    func testCompletedSingleFileCanBeMarkedUnreadWithoutMovingItsCursor() async throws {
        let location = "epubcfi(/6/8!/4/2/2:8)"
        let progress = makeSingleFileProgress(
            unit: .cfi,
            index: 9_900,
            total: 10_000,
            mode: .paged,
            location: location,
            completedAt: "2026-07-12T12:00:00Z"
        )
        let book = makeSingleFileBook(format: .epub, progress: progress)
        let reader = ReadingServiceStub(details: [bookID: book])
        let service = EntityDetailReadingService(reader: reader)

        _ = await service.toggleCompletion(
            detail: book,
            manifest: singleFileManifest(book),
            status: .completed
        )

        let updates = await reader.progressUpdatesSnapshot()
        let request = try XCTUnwrap(updates.first?.request)
        XCTAssertEqual(request.currentEntityID, bookID)
        XCTAssertEqual(request.index, 9_900)
        XCTAssertEqual(request.total, 10_000)
        XCTAssertEqual(request.completed, false)
        XCTAssertFalse(request.reset)
        XCTAssertEqual(request.location, location)
    }

    func testPageSequenceCapabilityLoadsAComicInstallmentWithoutBookKindChecks() async throws {
        let installment = try JSONDecoder().decode(
            EntityDetail.self,
            from: Data(
                """
                {
                  "id": "\(bookID)",
                  "kind": "comic-installment",
                  "title": "Chapter 12",
                  "hasSourceMedia": true,
                  "capabilities": [
                    {
                      "kind": "page-sequence",
                      "pageCount": 2,
                      "direction": "right-to-left",
                      "defaultMode": "paged",
                      "coverOrdinal": 0
                    },
                    {
                      "kind": "progress",
                      "currentEntityId": "\(bookID)",
                      "unit": "page",
                      "index": 1,
                      "total": 2,
                      "mode": "paged"
                    }
                  ],
                  "childrenByKind": [],
                  "relationships": []
                }
                """.utf8
            )
        )
        let manifest = try JSONDecoder().decode(
            EntityReaderManifest.self,
            from: Data(
                """
                {
                  "entityId": "\(bookID)",
                  "direction": "right-to-left",
                  "defaultMode": "paged",
                  "coverOrdinal": 0,
                  "pages": [
                    {
                      "ordinal": 0,
                      "mimeType": "image/jpeg",
                      "width": 1200,
                      "height": 1800,
                      "pageType": "front-cover",
                      "isDoublePage": false
                    },
                    {
                      "ordinal": 1,
                      "mimeType": "image/jpeg",
                      "width": 2400,
                      "height": 1800,
                      "pageType": "story",
                      "isDoublePage": true
                    }
                  ]
                }
                """.utf8
            )
        )
        let service = EntityDetailReadingService(
            reader: ReadingServiceStub(
                details: [bookID: installment],
                manifests: [bookID: manifest]
            )
        )

        let outcome = await service.load(detail: installment)

        guard case .content(let resolved) = outcome else {
            return XCTFail("Expected the page capability to select the generic reader.")
        }
        XCTAssertEqual(resolved.bookID, bookID)
        XCTAssertEqual(resolved.initialIndex, 1)
        XCTAssertEqual(resolved.readingDirection, .rightToLeft)
        XCTAssertEqual(resolved.pages.count, 2)
        XCTAssertTrue(resolved.pages[1].isDoublePage)
        XCTAssertTrue(resolved.completesAtManifestEnd)
    }

    private func makeManifest(
        bookID: UUID,
        title: String,
        completedAt: String? = nil
    ) -> BookReaderManifest {
        let chapterDetail = EntityDetail(
            id: chapterID,
            kind: .bookChapter,
            title: "Chapter One",
            parentEntityID: bookID,
            sortOrder: 0,
            hasSourceMedia: false,
            capabilities: [],
            childrenByKind: [],
            relationships: []
        )
        let page = BookReaderPage(
            id: pageID,
            title: "Page One",
            entityID: chapterID,
            ordinal: 0,
            isDoublePage: false
        )
        return BookReaderManifest(
            bookID: bookID,
            title: title,
            chapters: [BookReaderChapter(detail: chapterDetail, readerPages: [page], sequenceIndex: 0)],
            nextChapter: nil,
            progress: EntityProgressCapability(
                currentEntityID: chapterID,
                unit: .page,
                index: 0,
                total: 1,
                mode: .paged,
                completedAt: completedAt,
                updatedAt: nil,
                workIndex: 0,
                workTotal: 1,
                location: nil
            ),
            initialIndex: 0,
            readerMode: .paged
        )
    }

    private func makeSingleFileBook(
        format: BookFormat,
        progress: EntityProgressCapability?
    ) -> EntityDetail {
        EntityDetail(
            id: bookID,
            kind: .book,
            title: "Single File Book",
            parentEntityID: nil,
            sortOrder: nil,
            hasSourceMedia: true,
            capabilities: [.bookMetadata(.init(bookType: "book", format: format))]
                + (progress.map { [.progress($0)] } ?? []),
            childrenByKind: [],
            relationships: []
        )
    }

    private func makeSingleFileProgress(
        unit: ProgressUnit,
        index: Int,
        total: Int,
        mode: ReaderMode,
        location: String?,
        completedAt: String? = nil
    ) -> EntityProgressCapability {
        EntityProgressCapability(
            currentEntityID: bookID,
            unit: unit,
            index: index,
            total: total,
            mode: mode,
            completedAt: completedAt,
            updatedAt: nil,
            workIndex: nil,
            workTotal: nil,
            location: location
        )
    }

    private func singleFileManifest(_ detail: EntityDetail) -> BookReaderManifest {
        let progress: EntityProgressCapability?
        if let capability = detail.capabilities.first(where: { capability in
            if case .progress = capability { return true }
            return false
        }), case .progress(let value) = capability {
            progress = value
        } else {
            progress = nil
        }
        return BookReaderManifest(
            bookID: detail.id,
            title: detail.title,
            chapters: [],
            nextChapter: nil,
            progress: progress,
            initialIndex: 0,
            readerMode: progress?.mode ?? .paged
        )
    }
}

private actor ReadingServiceStub: BookReaderServicing {
    struct ProgressUpdate: Sendable {
        let id: UUID
        let request: EntityProgressUpdateRequest
    }

    let details: [UUID: EntityDetail]
    let manifests: [UUID: EntityReaderManifest]
    private(set) var progressUpdates: [ProgressUpdate] = []

    init(
        details: [UUID: EntityDetail],
        manifests: [UUID: EntityReaderManifest] = [:]
    ) {
        self.details = details
        self.manifests = manifests
    }

    func loadEntity(id: UUID) async throws -> EntityDetail {
        guard let detail = details[id] else { throw ReadingTestError.missingEntity }
        return detail
    }

    func loadPageData(id: UUID) async throws -> Data {
        return Data()
    }

    func loadEntityReaderManifest(id: UUID) async throws -> EntityReaderManifest {
        guard let manifest = manifests[id] else { throw ReadingTestError.missingEntity }
        return manifest
    }

    func updateReadingProgress(id: UUID, request: EntityProgressUpdateRequest) async throws {
        progressUpdates.append(.init(id: id, request: request))
    }

    func progressUpdatesSnapshot() -> [ProgressUpdate] {
        progressUpdates
    }
}

private enum ReadingTestError: Error, LocalizedError {
    case missingEntity

    var errorDescription: String? {
        switch self {
        case .missingEntity: "The entity is missing."
        }
    }
}
