import XCTest

@testable import PrismediaCore

final class BookChapterMappingAPIClientTests: XCTestCase {
    func testLoadsAndReplacesBookChapterMappingsUsingTheSharedContract() async throws {
        let bookID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let trackID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let response = #"{"mappings":[{"readableChapterKey":"Text/prologue.xhtml","audioTrackId":"\#(trackID)"}]}"#
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
            mappings: loaded
        )

        XCTAssertEqual(loaded.first?.readableChapterKey, "Text/prologue.xhtml")
        XCTAssertEqual(saved.first?.audioTrackID, trackID)
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
        XCTAssertEqual(mappings.first?["readableChapterKey"] as? String, "Text/prologue.xhtml")
        XCTAssertEqual(mappings.first?["audioTrackId"] as? String, trackID.uuidString)
        XCTAssertNil(mappings.first?["audioTrackID"])
    }
}
