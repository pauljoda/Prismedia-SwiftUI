import XCTest

@testable import PrismediaCore

final class EntityListResponseTests: XCTestCase {
    func testDecodesPrismediaEntityListWithDefaults() throws {
        let json = """
            {
              "items": [
                {
                  "id": "11111111-1111-1111-1111-111111111111",
                  "kind": "video",
                  "title": "Bahld Harmon birthplace (disputed)",
                  "coverUrl": "/assets/videos/11111111-1111-1111-1111-111111111111/thumb.jpg",
                  "meta": [{ "icon": "duration", "label": "30:32" }],
                  "isFavorite": true
                }
              ],
              "nextCursor": null,
              "totalCount": 1
            }
            """.data(using: .utf8)!

        let response = try JSONDecoder().decode(EntityListResponse.self, from: json)

        XCTAssertEqual(response.items.count, 1)
        XCTAssertEqual(response.items[0].kind, .video)
        XCTAssertEqual(response.items[0].meta[0].label, "30:32")
        XCTAssertTrue(response.items[0].isFavorite)
        XCTAssertFalse(response.items[0].isNsfw)
    }
}
