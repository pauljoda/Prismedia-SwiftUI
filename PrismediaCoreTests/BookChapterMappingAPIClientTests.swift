import XCTest

@testable import PrismediaCore

final class BookChapterMappingAPIClientTests: XCTestCase {
    func testLoadsAndReplacesBookChapterMappingsUsingTheSharedContract() async throws {
        let bookID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let trackID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let autoTrackID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        let markerID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
        let response = #"""
            {"mappings":[
                {"readableChapterKey":"Text/prologue.xhtml","audioTrackId":"\#(trackID)","audioMarkerId":"\#(markerID)","origin":"manual"},
                {"readableChapterKey":"Text/chapter-01.xhtml","audioTrackId":"\#(autoTrackID)","origin":"auto"}
            ],"audioChapters":[
                {"audioTrackId":"\#(trackID)","audioMarkerId":"\#(markerID)","title":"Prologue","startSeconds":12.5,"endSeconds":80.0}
            ]}
            """#
        let loader = MockHTTPDataLoader(responses: [
            .json(response),
            .json(response),
        ])
        let client = PrismediaAPIClient(
            serverURL: URL(string: "https://media.example.test")!,
            accessToken: "token",
            loader: loader
        )

        let loaded = try await client.loadBookChapterMappings(bookID: bookID)
        let saved = try await client.replaceBookChapterMappings(
            bookID: bookID,
            mappings: loaded.mappings.filter { !$0.isAutomatic }
        )

        XCTAssertEqual(loaded.mappings.first?.readableChapterKey, "Text/prologue.xhtml")
        XCTAssertEqual(loaded.mappings.map(\.isAutomatic), [false, true])
        XCTAssertEqual(loaded.mappings.first?.audioMarkerID, markerID)
        XCTAssertEqual(loaded.audioChapters.first?.startSeconds, 12.5)
        XCTAssertEqual(saved.mappings.first?.audioTrackID, trackID)
        XCTAssertEqual(
            loader.requests.map { $0.url?.path },
            [
                "/api/books/\(bookID.uuidString.lowercased())/chapter-mappings",
                "/api/books/\(bookID.uuidString.lowercased())/chapter-mappings",
            ]
        )
        XCTAssertEqual(loader.requests.map(\.httpMethod), ["GET", "PUT"])
        XCTAssertTrue(
            loader.requests.allSatisfy {
                $0.value(forHTTPHeaderField: "Authorization") == "Bearer token"
            })

        let body = try XCTUnwrap(loader.requests.last?.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        let mappings = try XCTUnwrap(json["mappings"] as? [[String: Any]])
        // Only the manual layer may be saved; echoing automatic rows would promote them.
        XCTAssertEqual(mappings.count, 1)
        XCTAssertEqual(mappings.first?["readableChapterKey"] as? String, "Text/prologue.xhtml")
        XCTAssertEqual(mappings.first?["audioTrackId"] as? String, trackID.uuidString)
        XCTAssertEqual(mappings.first?["audioMarkerId"] as? String, markerID.uuidString)
        XCTAssertNil(mappings.first?["audioTrackID"])
    }
}
