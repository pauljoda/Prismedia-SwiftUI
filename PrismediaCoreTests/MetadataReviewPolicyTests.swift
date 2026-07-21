import XCTest

@testable import PrismediaCore

final class MetadataReviewPolicyTests: XCTestCase {
    func testFindsProposalRecursivelyAcrossChildrenAndRelationships() {
        let credit = proposal(id: "credit", kind: "person", title: "Amy Adams")
        let episode = proposal(
            id: "episode",
            kind: "video-episode",
            title: "Episode 1",
            relationships: [credit]
        )
        let season = proposal(
            id: "season",
            kind: "video-season",
            title: "Season 1",
            children: [episode]
        )
        let root = proposal(
            id: "root",
            kind: "video-series",
            title: "Series",
            children: [season]
        )

        XCTAssertEqual(
            MetadataReviewPolicy.proposal(withID: "credit", in: root)?.patch.title,
            "Amy Adams"
        )
        XCTAssertNil(MetadataReviewPolicy.proposal(withID: "missing", in: root))
    }

    func testSeparatesStructuralChildrenFromDeduplicatedRelationships() {
        let person = proposal(id: "person", kind: "person", title: "Amy Adams")
        let child = proposal(id: "season", kind: "video-season", title: "Season 1")
        let root = proposal(
            id: "root",
            kind: "video-series",
            title: "Arrival",
            children: [person, child, person],
            relationships: [person]
        )

        XCTAssertEqual(MetadataReviewPolicy.structuralChildren(of: root).map(\.proposalID), ["season"])
        XCTAssertEqual(MetadataReviewPolicy.relationships(of: root).map(\.proposalID), ["person"])
    }

    func testSeededSelectionSelectsPopulatedFieldsFirstArtworkAndGranularValues() {
        let root = proposal(
            id: "root",
            kind: "movie",
            title: "Arrival",
            tags: ["Science Fiction", "Drama"],
            credits: [AdministrativeCreditPatch(name: "Amy Adams", role: "actor", character: nil, sortOrder: 1)],
            images: [
                AdministrativeImageCandidate(
                    kind: "poster", url: "https://example.test/one.jpg", source: "tmdb",
                    rank: nil, language: nil, width: nil, height: nil),
                AdministrativeImageCandidate(
                    kind: "poster", url: "https://example.test/two.jpg", source: "tmdb",
                    rank: nil, language: nil, width: nil, height: nil),
                AdministrativeImageCandidate(
                    kind: "logo", url: "https://example.test/logo.png", source: "tmdb",
                    rank: nil, language: nil, width: nil, height: nil),
            ]
        )

        let selection = MetadataReviewPolicy.seededSelection(for: root)

        XCTAssertTrue(selection.selectedFieldsByProposal["root"]?.contains(.title) == true)
        XCTAssertTrue(selection.selectedFieldsByProposal["root"]?.contains(.tags) == true)
        XCTAssertFalse(selection.selectedFieldsByProposal["root"]?.contains(.description) == true)
        XCTAssertEqual(selection.selectedImagesByProposal["root"], ["poster": "https://example.test/one.jpg"])
        XCTAssertEqual(selection.selectedTagsByProposal["root"], ["Science Fiction", "Drama"])
        XCTAssertEqual(selection.selectedCreditsByProposal["root"]?.count, 1)
    }

    func testProposalForApplyRemovesDeselectedFieldsItemsArtworkAndNodes() {
        let excludedPerson = proposal(id: "person-2", kind: "person", title: "Jeremy Renner")
        let includedPerson = proposal(id: "person-1", kind: "person", title: "Amy Adams")
        let excludedChild = proposal(id: "season-2", kind: "video-season", title: "Season 2")
        let includedChild = proposal(id: "season-1", kind: "video-season", title: "Season 1")
        let root = proposal(
            id: "root",
            kind: "video-series",
            title: "Arrival",
            description: "Proposed description",
            tags: ["Science Fiction", "Drama"],
            credits: [
                AdministrativeCreditPatch(name: "Amy Adams", role: "actor", character: nil, sortOrder: 1),
                AdministrativeCreditPatch(name: "Jeremy Renner", role: "actor", character: nil, sortOrder: 2),
            ],
            images: [
                AdministrativeImageCandidate(
                    kind: "poster", url: "https://example.test/one.jpg", source: "tmdb",
                    rank: nil, language: nil, width: nil, height: nil),
                AdministrativeImageCandidate(
                    kind: "poster", url: "https://example.test/two.jpg", source: "tmdb",
                    rank: nil, language: nil, width: nil, height: nil),
            ],
            children: [includedChild, excludedChild],
            relationships: [includedPerson, excludedPerson]
        )
        var selection = MetadataReviewPolicy.seededSelection(for: root)
        selection.selectedFieldsByProposal["root"]?.remove(.description)
        selection.selectedTagsByProposal["root"] = ["Science Fiction"]
        selection.selectedCreditsByProposal["root"] = [
            MetadataReviewPolicy.creditKey(root.patch.credits[0], index: 0)
        ]
        selection.selectedImagesByProposal["root"] = ["poster": "https://example.test/two.jpg"]
        selection.excludedProposalIDs = ["season-2"]

        let applied = MetadataReviewPolicy.proposalForApply(root, selection: selection)

        XCTAssertNil(applied.patch.description)
        XCTAssertEqual(applied.patch.tags, ["Science Fiction"])
        XCTAssertEqual(applied.patch.credits.map(\.name), ["Amy Adams"])
        XCTAssertEqual(applied.images.map(\.url), ["https://example.test/two.jpg"])
        XCTAssertEqual(applied.children.map(\.proposalID), ["season-1"])
        XCTAssertEqual(applied.relationships.map(\.proposalID), ["person-1"])
    }

    private func proposal(
        id: String,
        kind: String,
        title: String,
        description: String? = nil,
        tags: [String] = [],
        credits: [AdministrativeCreditPatch] = [],
        images: [AdministrativeImageCandidate] = [],
        children: [AdministrativeEntityMetadataProposal] = [],
        relationships: [AdministrativeEntityMetadataProposal] = []
    ) -> AdministrativeEntityMetadataProposal {
        AdministrativeEntityMetadataProposal(
            proposalID: id,
            provider: "tmdb",
            targetKind: kind,
            confidence: 1,
            matchReason: "external-id",
            patch: AdministrativeEntityMetadataPatch(
                title: title,
                description: description,
                externalIDs: ["tmdb": id],
                urls: [],
                tags: tags,
                studio: nil,
                credits: credits,
                dates: [:],
                stats: [:],
                positions: [:],
                classification: nil,
                rating: nil,
                flags: nil
            ),
            images: images,
            children: children,
            candidates: [],
            targetEntityID: nil,
            relationships: relationships
        )
    }
}
