import XCTest

@testable import PrismediaCore

final class TVPlaybackCatalogLoaderTests: XCTestCase {
    func testTVMoviePagingRequiresFilesWithoutChangingSharedQueries() async throws {
        let transport = MockHTTPDataLoader(responses: [.json(#"{"items":[],"nextCursor":null,"totalCount":0}"#)])
        let loader = TVPlaybackCatalogLoader(
            client: PrismediaAPIClient(
                serverURL: URL(string: "https://media.example.test")!, accessToken: "token", loader: transport))
        let query = EntityListQuery(kind: .movie, hasFile: false)
        _ = try await loader.load(query: query, limit: 20, search: "Film", cursor: "next")
        let url = try XCTUnwrap(transport.requests.first?.url)
        let values = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        XCTAssertEqual(values.first { $0.name == "hasFile" }?.value, "true")
        XCTAssertEqual(values.first { $0.name == "cursor" }?.value, "next")
        XCTAssertEqual(query.hasFile, false)
    }

    func testCollectionsUsePlayableMembershipBeforePagingAndCounting() async throws {
        let emptyID = "11111111-1111-1111-1111-111111111111"
        let readyID = "22222222-2222-2222-2222-222222222222"
        let transport = MockHTTPDataLoader(responses: [
            .json(
                """
                {"items":[{"id":"\(emptyID)","kind":"collection","title":"Pending"}],"nextCursor":"next","totalCount":2}
                """),
            .json(
                #"{"items":[{"entity":{"id":"33333333-3333-3333-3333-333333333333","kind":"movie","title":"Pending","hasSourceMedia":false}}]}"#
            ),
            .json(
                """
                {"items":[{"id":"\(readyID)","kind":"collection","title":"Ready"}],"nextCursor":null,"totalCount":2}
                """),
            .json(
                #"{"items":[{"entity":{"id":"44444444-4444-4444-4444-444444444444","kind":"movie","title":"Ready","hasSourceMedia":true}}]}"#
            ),
        ])
        let loader = TVPlaybackCatalogLoader(
            client: PrismediaAPIClient(
                serverURL: URL(string: "https://media.example.test")!, accessToken: "token", loader: transport))
        let page = try await loader.load(query: EntityListQuery(kind: .collection), limit: 1, search: nil, cursor: nil)
        XCTAssertEqual(page.items.map(\.id), [UUID(uuidString: readyID)!])
        XCTAssertEqual(page.totalCount, 1)
        XCTAssertNil(page.nextCursor)
        XCTAssertEqual(transport.requests.count, 4)
    }

    func testTVShelvesRejectPendingAndNonVideoEntries() {
        let shelf = TVAppCatalog.homeShelves[0]
        XCTAssertTrue(TVAppCatalog.homeShelves.allSatisfy { $0.query.hasFile == true })
        XCTAssertFalse(shelf.accepts(EntityThumbnail(id: UUID(), kind: .movie, title: "Pending")))
        XCTAssertFalse(shelf.accepts(EntityThumbnail(id: UUID(), kind: .book, title: "Book", hasSourceMedia: true)))
        XCTAssertTrue(
            shelf.accepts(EntityThumbnail(id: UUID(), kind: .videoSeries, title: "Series", hasSourceMedia: true)))
    }
}
