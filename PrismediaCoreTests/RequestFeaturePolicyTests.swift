import XCTest

@testable import PrismediaCore

final class RequestFeaturePolicyTests: XCTestCase {
    func testSelectionUsesRegistryModesAndOnlyDirectStructuralTargets() {
        let volume = proposal(id: "volume", kind: "book-volume")
        let nested = proposal(id: "chapter", kind: "book-chapter")
        let relationship = proposal(id: "person", kind: "person")
        let root = proposal(id: "root", kind: "book", children: [volume, nested], relationships: [relationship])
        let review = review(
            kind: "book", proposal: root,
            targets: [
                target(id: "root", requestable: true),
                target(id: "volume", requestable: true),
                target(id: "chapter", requestable: true),
                target(id: "person", requestable: true),
            ])

        let selection = RequestSelectionPolicy.derive(from: review)

        XCTAssertEqual(selection.mode, .directChildren)
        XCTAssertEqual(selection.selectableIDs, ["volume", "chapter"])
        XCTAssertFalse(selection.selectableIDs.contains("person"))
        XCTAssertTrue(selection.rootSelection.isEmpty)
    }

    func testBookWithoutChildrenAndLeafKindsSelectOnlyRequestableRoot() {
        let proposal = proposal(id: "root", kind: "book")
        let book = RequestSelectionPolicy.derive(
            from: review(kind: "book", proposal: proposal, targets: [target(id: "root", requestable: true)]))
        let movie = RequestSelectionPolicy.derive(
            from: review(kind: "movie", proposal: proposal, targets: [target(id: "root", requestable: false)]))

        XCTAssertEqual(book.mode, .root)
        XCTAssertEqual(book.rootSelection, ["root"])
        XCTAssertEqual(movie.mode, .root)
        XCTAssertTrue(movie.rootSelection.isEmpty)
    }

    func testPresetsMirrorBackendAndHandEditsBecomeCustom() {
        let children = [target(id: "one", requestable: true), target(id: "owned", requestable: false)]

        XCTAssertEqual(RequestPresetPolicy.selectedIDs(for: .all, children: children), ["one"])
        XCTAssertEqual(RequestPresetPolicy.selectedIDs(for: .missing, children: children), ["one"])
        XCTAssertTrue(RequestPresetPolicy.selectedIDs(for: .future, children: children).isEmpty)
        XCTAssertTrue(RequestPresetPolicy.selectedIDs(for: .manual, children: children).isEmpty)
        XCTAssertEqual(RequestPresetPolicy.matchingPreset(selectedIDs: ["one", "extra"], children: children), .custom)
        XCTAssertNil(RequestMonitorPreset.custom.wireValue)
        XCTAssertEqual(RequestMonitorPreset.manual.wireValue, "none")
    }

    func testTargetFilteringUsesProfileKindCapabilityVisibilityAndProfileDefault() {
        let bookRoot = root(id: "11111111-1111-1111-1111-111111111111", label: "Books", books: true)
        let nsfwBookRoot = root(
            id: "22222222-2222-2222-2222-222222222222", label: "NSFW", books: true, isNsfw: true)
        let movieRoot = root(id: "33333333-3333-3333-3333-333333333333", label: "Movies", videos: true)
        let profile = AdministrativeAcquisitionProfile(
            id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
            kind: .book,
            displayName: "Books HD",
            isDefault: true,
            targetLibraryRootID: bookRoot.id
        )
        let incompatible = AdministrativeAcquisitionProfile(
            id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
            kind: .movie,
            displayName: "Movies",
            isDefault: true,
            targetLibraryRootID: movieRoot.id
        )

        let roots = RequestTargetPolicy.roots(
            for: .book,
            from: [movieRoot, nsfwBookRoot, bookRoot],
            hidesNsfw: true
        )
        let profiles = RequestTargetPolicy.profiles(for: .book, from: [incompatible, profile])

        XCTAssertEqual(roots.map(\.id), [bookRoot.id])
        XCTAssertEqual(profiles.map(\.id), [profile.id])
        XCTAssertEqual(RequestTargetPolicy.defaultProfile(for: .book, from: [incompatible, profile])?.id, profile.id)
        XCTAssertEqual(RequestTargetPolicy.defaultRootID(for: profile, compatibleRoots: roots), bookRoot.id)
    }

    func testRevisionRejectsStaleResults() {
        var revision = RequestLoadRevision()
        let first = revision.advance()
        let second = revision.advance()

        XCTAssertFalse(revision.isCurrent(first))
        XCTAssertTrue(revision.isCurrent(second))
    }

    func testCandidateActivationRequiresPluginAndExternalIdentity() throws {
        let valid = try requestResult(pluginID: "tmdb", includesIdentity: true)
        let missingPlugin = try requestResult(pluginID: nil, includesIdentity: true)
        let missingIdentity = try requestResult(pluginID: "tmdb", includesIdentity: false)

        XCTAssertEqual(RequestCandidatePolicy.route(for: valid, kind: .movie)?.externalIdentity.value, "603")
        XCTAssertNil(RequestCandidatePolicy.route(for: missingPlugin, kind: .movie))
        XCTAssertNil(RequestCandidatePolicy.route(for: missingIdentity, kind: .movie))
    }

    func testOutcomePolicyCreatesEntityIntentAndDistinguishesDuplicates() {
        let entityID = UUID(uuidString: "66666666-6666-6666-6666-666666666666")!
        let review = review(
            kind: "movie",
            proposal: proposal(id: "root", kind: "movie"),
            targets: [target(id: "root", requestable: true)]
        )
        let requested = RequestCommitOutcomePolicy.resolve(
            response: AdministrativeRequestCommitResponse(
                containerEntityID: nil,
                items: [
                    AdministrativeRequestCommitItem(
                        externalID: "tmdb:603",
                        title: "The Matrix",
                        outcome: "requested",
                        entityID: entityID,
                        acquisitionID: UUID()
                    )
                ]
            ),
            review: review
        )
        let owned = RequestCommitOutcomePolicy.resolve(
            response: AdministrativeRequestCommitResponse(
                containerEntityID: nil,
                items: [
                    AdministrativeRequestCommitItem(
                        externalID: "tmdb:603",
                        title: "The Matrix",
                        outcome: "already-owned",
                        entityID: entityID,
                        acquisitionID: nil
                    )
                ]
            ),
            review: review
        )

        XCTAssertEqual(requested.navigationIntent?.entityID, entityID)
        XCTAssertEqual(requested.navigationIntent?.entityKind, .movie)
        XCTAssertEqual(owned.title, "Already in Library")
    }

    private func proposal(
        id: String,
        kind: String,
        children: [AdministrativeEntityMetadataProposal] = [],
        relationships: [AdministrativeEntityMetadataProposal] = []
    ) -> AdministrativeEntityMetadataProposal {
        AdministrativeEntityMetadataProposal(
            proposalID: id,
            provider: "tmdb",
            targetKind: kind,
            confidence: nil,
            matchReason: nil,
            patch: AdministrativeEntityMetadataPatch(
                title: id,
                description: nil,
                externalIDs: [:],
                urls: [],
                tags: [],
                studio: nil,
                credits: [],
                dates: [:],
                stats: [:],
                positions: [:],
                classification: nil,
                rating: nil,
                flags: nil
            ),
            images: [],
            children: children,
            candidates: [],
            targetEntityID: nil,
            relationships: relationships
        )
    }

    private func target(id: String, requestable: Bool) -> AdministrativeRequestReviewTarget {
        AdministrativeRequestReviewTarget(
            proposalID: id,
            kind: "movie",
            entityKind: .movie,
            externalIdentity: AdministrativeExternalIdentity(namespace: "tmdb", value: "603"),
            requestable: requestable,
            position: nil,
            year: nil,
            monitored: nil
        )
    }

    private func review(
        kind: String,
        proposal: AdministrativeEntityMetadataProposal,
        targets: [AdministrativeRequestReviewTarget]
    ) -> AdministrativeRequestReviewResponse {
        AdministrativeRequestReviewResponse(
            pluginID: "tmdb",
            externalIdentity: AdministrativeExternalIdentity(namespace: "tmdb", value: "603"),
            entityKind: .movie,
            kind: kind,
            proposal: proposal,
            revision: "revision-1",
            targets: targets
        )
    }

    private func root(
        id: String,
        label: String,
        books: Bool = false,
        videos: Bool = false,
        isNsfw: Bool = false
    ) -> AdministrativeLibraryRoot {
        AdministrativeLibraryRoot(
            id: UUID(uuidString: id)!,
            path: "/media/\(label)",
            label: label,
            enabled: true,
            scanVideos: videos,
            scanBooks: books,
            isNsfw: isNsfw
        )
    }

    private func requestResult(
        pluginID: String?,
        includesIdentity: Bool
    ) throws -> AdministrativeRequestSearchResult {
        let pluginJSON = pluginID.map { "\"\($0)\"" } ?? "null"
        let identityJSON =
            includesIdentity
            ? #"{"namespace":"tmdb","value":"603"}"#
            : "null"
        let json =
            #"{"serviceId":"99999999-9999-9999-9999-999999999999","source":"plugin","kind":"movie","externalId":"tmdb:603","title":"The Matrix","subtitle":null,"year":1999,"overview":null,"posterUrl":null,"backdropUrl":null,"rating":null,"runtimeMinutes":null,"certification":null,"trackCount":null,"tags":[],"tracked":false,"upstreamId":null,"monitored":null,"requestable":true,"providerName":"TMDB","pluginId":\#(pluginJSON),"externalIdentity":\#(identityJSON)}"#
        return try PrismediaJSON.decoder().decode(AdministrativeRequestSearchResult.self, from: Data(json.utf8))
    }
}
