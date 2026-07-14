import XCTest

@testable import PrismediaCore

final class AdministrativeContractModelTests: XCTestCase {
    func testAudiobookIsAFirstClassDiscoverableRequestKind() {
        XCTAssertTrue(AdministrativeRequestKind.allCases.contains(.audiobook))
        XCTAssertEqual(AdministrativeRequestKind.audiobook.entityKind, "book")
        XCTAssertEqual(AdministrativeRequestKind.audiobook.title, "Audiobook")
    }

    func testProposalGraphDecodesNestedChildrenRelationshipsAndCandidateIdentity() throws {
        let json =
            #"{"proposalId":"root","provider":"tmdb","targetKind":"video-series","confidence":0.9,"matchReason":"title","patch":{"title":"Series","description":null,"externalIds":{"tmdb":"1"},"urls":[],"tags":[],"studio":null,"credits":[],"dates":{},"stats":{},"positions":{},"classification":null,"rating":null,"flags":null},"images":[],"children":[{"proposalId":"season-1","provider":"tmdb","targetKind":"video-season","confidence":null,"matchReason":null,"patch":{"title":"Season 1","description":null,"externalIds":{"tmdb":"2"},"urls":[],"tags":[],"studio":null,"credits":[],"dates":{},"stats":{},"positions":{"season":1},"classification":null,"rating":null,"flags":null},"images":[],"children":[],"candidates":[],"targetEntityId":null,"relationships":[]}],"candidates":[{"externalIds":{"tmdb":"1"},"title":"Series","year":2026,"overview":null,"posterUrl":null,"popularity":1,"candidateId":"1","source":"tmdb","confidence":0.9,"matchReason":"title"}],"targetEntityId":null,"relationships":[{"proposalId":"person-1","provider":"tmdb","targetKind":"person","confidence":null,"matchReason":null,"patch":{"title":"Actor","description":null,"externalIds":{"tmdb":"3"},"urls":[],"tags":[],"studio":null,"credits":[],"dates":{},"stats":{},"positions":{},"classification":null,"rating":null,"flags":null},"images":[],"children":[],"candidates":[],"targetEntityId":null,"relationships":[]}]}"#

        let proposal = try PrismediaJSON.decoder().decode(
            AdministrativeEntityMetadataProposal.self,
            from: Data(json.utf8)
        )

        XCTAssertEqual(proposal.children.first?.patch.title, "Season 1")
        XCTAssertEqual(proposal.relationships.first?.targetKind, "person")
        XCTAssertEqual(proposal.candidates.first?.externalIDs, ["tmdb": "1"])
    }
}
