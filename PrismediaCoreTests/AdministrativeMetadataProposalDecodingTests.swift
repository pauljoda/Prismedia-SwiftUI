import Foundation
import XCTest

@testable import PrismediaCore

/// Prismedia serializes empty proposal collections as explicit JSON nulls
/// (`"candidates": null`, `"relationships": null`, sparse patch maps). The
/// review surfaces must keep decoding those trees; a strict array decode here
/// breaks every real-server request review and identify proposal.
final class AdministrativeMetadataProposalDecodingTests: XCTestCase {
    func testDecodesProposalTreeWithNullCollections() throws {
        let json = """
            {
              "proposalId": "tmdb:movie:556574",
              "provider": "tmdb",
              "targetKind": "movie",
              "confidence": 1,
              "matchReason": "external-id",
              "patch": {
                "title": "Hamilton",
                "description": null,
                "externalIds": null,
                "urls": null,
                "tags": null,
                "studio": null,
                "credits": null,
                "dates": null,
                "stats": null,
                "positions": null,
                "classification": null,
                "rating": null,
                "flags": null
              },
              "images": null,
              "children": null,
              "candidates": null,
              "targetEntityId": null,
              "relationships": [
                {
                  "proposalId": "tmdb:person:1",
                  "provider": "tmdb",
                  "targetKind": "person",
                  "confidence": null,
                  "matchReason": null,
                  "patch": { "title": "Lin-Manuel Miranda" },
                  "images": null,
                  "children": null,
                  "candidates": null,
                  "targetEntityId": null,
                  "relationships": null
                }
              ]
            }
            """
        let proposal = try JSONDecoder().decode(
            AdministrativeEntityMetadataProposal.self,
            from: Data(json.utf8)
        )
        XCTAssertEqual(proposal.proposalID, "tmdb:movie:556574")
        XCTAssertTrue(proposal.candidates.isEmpty)
        XCTAssertTrue(proposal.children.isEmpty)
        XCTAssertTrue(proposal.images.isEmpty)
        XCTAssertTrue(proposal.patch.urls.isEmpty)
        XCTAssertTrue(proposal.patch.stats.isEmpty)
        XCTAssertEqual(proposal.relationships.count, 1)
        XCTAssertEqual(proposal.relationships[0].patch.title, "Lin-Manuel Miranda")
        XCTAssertTrue(proposal.relationships[0].relationships.isEmpty)
    }
}
