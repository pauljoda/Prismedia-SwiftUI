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

        private func queueItem() throws -> AdministrativeIdentifyQueueItem {
            let id = UUID()
            let entityID = UUID()
            let data = Data(
                """
                {
                  "id": "\(id.uuidString)",
                  "entityId": "\(entityID.uuidString)",
                  "entityKind": "movie",
                  "title": "Arrival",
                  "isNsfw": false,
                  "state": "queued",
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
