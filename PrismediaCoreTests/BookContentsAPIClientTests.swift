import XCTest

@testable import PrismediaCore

final class BookContentsAPIClientTests: XCTestCase {
    func testLoadsCompactBookContentsWithoutRequestingTheSourceArchive() async throws {
        let bookID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let loader = MockHTTPDataLoader(responses: [
            .json(
                #"{"items":[{"id":"Text/chapter-1.xhtml","title":"Chapter One","location":"Text/chapter-1.xhtml","depth":"1","order":0,"sectionIndex":"2","startFraction":"0.25","endFraction":0.5,"pageCount":null}]}"#
            )
        ])
        let client = PrismediaAPIClient(
            serverURL: URL(string: "https://media.example.test")!,
            accessToken: "token",
            loader: loader
        )

        let contents = try await client.loadBookContents(bookID: bookID)

        XCTAssertEqual(contents.count, 1)
        XCTAssertEqual(contents.first?.id, "Text/chapter-1.xhtml")
        XCTAssertEqual(contents.first?.depth, 1)
        XCTAssertEqual(contents.first?.sectionIndex, 2)
        XCTAssertEqual(contents.first?.startFraction, 0.25)
        XCTAssertEqual(contents.first?.endFraction, 0.5)
        XCTAssertNil(contents.first?.pageCount)
        XCTAssertEqual(loader.requests.count, 1)
        XCTAssertEqual(
            loader.requests.first?.url?.path,
            "/api/books/\(bookID.uuidString.lowercased())/contents"
        )
        XCTAssertEqual(loader.requests.first?.httpMethod, "GET")
        XCTAssertEqual(
            loader.requests.first?.value(forHTTPHeaderField: "Authorization"),
            "Bearer token"
        )
    }
}
