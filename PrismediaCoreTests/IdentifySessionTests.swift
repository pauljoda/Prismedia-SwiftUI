import XCTest

@testable import PrismediaCore

#if os(iOS) || os(macOS)
    final class IdentifySessionTests: XCTestCase {
        @MainActor
        func testOpeningMissingQueueItemCreatesItWithoutStartingSearch() async throws {
            let item = try queueItem()
            let service = OpenIdentifyServiceSpy(item: item)
            let session = IdentifySession(service: service, browser: IdentifyPreviewEntityBrowser())

            await session.open(entityID: item.entityID)

            let counts = await service.callCounts()
            XCTAssertEqual(counts.get, 1)
            XCTAssertEqual(counts.add, 1)
            XCTAssertEqual(counts.search, 0)
            XCTAssertEqual(session.selectedItemID, item.entityID)
        }

        @MainActor
        func testBackgroundQueueRefreshReconcilesSelectionWithoutAFullLoad() async throws {
            let first = try queueItem(title: "Arrival")
            let second = try queueItem(title: "Dune")
            let service = OpenIdentifyServiceSpy(item: first, queue: [second])
            let session = IdentifySession(
                service: service,
                browser: IdentifyPreviewEntityBrowser(),
                initialQueue: [first]
            )
            session.selectedQueueIDs = [first.entityID, second.entityID]

            await session.refreshQueue()

            XCTAssertEqual(session.queue, [second])
            XCTAssertEqual(session.selectedItemID, second.entityID)
            XCTAssertEqual(session.selectedQueueIDs, [second.entityID])
            XCTAssertFalse(session.isLoading)
        }

        @MainActor
        func testBeginningEntityEntryPersistsQueueBeforeStartingProviderSearch() async throws {
            let item = try queueItem(state: "search")
            let service = OpenIdentifyServiceSpy(item: item)
            let session = IdentifySession(
                service: service,
                browser: IdentifyPreviewEntityBrowser()
            )

            await session.beginEntry(entityID: item.entityID)

            let counts = await service.callCounts()
            let callOrder = await service.callOrder()
            XCTAssertEqual(counts.get, 1)
            XCTAssertEqual(counts.add, 1)
            XCTAssertEqual(counts.search, 1)
            XCTAssertEqual(callOrder, ["get", "add", "search"])
            XCTAssertEqual(session.selectedItemID, item.entityID)
        }

        private func queueItem(
            title: String = "Arrival",
            state: String = "queued"
        ) throws -> AdministrativeIdentifyQueueItem {
            let id = UUID()
            let entityID = UUID()
            let data = Data(
                """
                {
                  "id": "\(id.uuidString)",
                  "entityId": "\(entityID.uuidString)",
                  "entityKind": "movie",
                  "title": "\(title)",
                  "isNsfw": false,
                  "state": "\(state)",
                  "action": "identify",
                  "candidates": [],
                  "cascadeRunning": false,
                  "createdAt": "2026-07-12T12:00:00Z",
                  "updatedAt": "2026-07-12T12:00:00Z"
                }
                """.utf8)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(AdministrativeIdentifyQueueItem.self, from: data)
        }
    }
#endif
