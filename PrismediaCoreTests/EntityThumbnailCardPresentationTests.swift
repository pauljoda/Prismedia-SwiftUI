import XCTest

@testable import PrismediaCore

final class EntityThumbnailCardPresentationTests: XCTestCase {
    func testThumbnailDecodesConciseDescriptionFromExistingServerNames() throws {
        let description = try decodeThumbnail(descriptionMember: #""description":"A description.""#)
        let overview = try decodeThumbnail(descriptionMember: #""overview":"An overview.""#)
        let summary = try decodeThumbnail(descriptionMember: #""summary":"A summary.""#)

        XCTAssertEqual(description.summary, "A description.")
        XCTAssertEqual(overview.summary, "An overview.")
        XCTAssertEqual(summary.summary, "A summary.")
    }

    private func decodeThumbnail(descriptionMember: String) throws -> EntityThumbnail {
        let data = Data(
            """
            {
              "id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
              "kind": "video",
              "title": "Episode",
              \(descriptionMember)
            }
            """.utf8
        )
        return try PrismediaJSON.decoder().decode(EntityThumbnail.self, from: data)
    }
}
