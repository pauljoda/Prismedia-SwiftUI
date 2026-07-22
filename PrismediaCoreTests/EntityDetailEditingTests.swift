import XCTest

@testable import PrismediaCore

@MainActor
final class EntityDetailEditingTests: XCTestCase {
    func testMainEditRequestPreservesCompleteCreditMetadata() throws {
        let detail = try makeDetail()
        var draft = EntityDetailEditDraft(detail: detail)
        draft.title = "Signal Revised"
        draft.credits[0].character = "Dr. Hale"
        let service = EntityDetailEditService(
            metadataMutator: MetadataMutatorStub(detail: detail),
            userMetadataMutator: nil
        )

        let request = try service.metadataRequest(
            draft: draft,
            detail: detail,
            section: .main
        )

        XCTAssertEqual(request.fields, ["title", "description", "tags", "studio", "credits"])
        XCTAssertEqual(request.patch.title, "Signal Revised")
        XCTAssertEqual(request.patch.credits.map(\.role), ["actor", "producer", "actor"])
        XCTAssertEqual(request.patch.credits.compactMap(\.character), ["Dr. Hale", "The Witness"])
    }

    func testEditDraftKeepsEntityReferencesTyped() throws {
        let detail = try makeDetail()

        let draft = EntityDetailEditDraft(detail: detail)

        XCTAssertEqual(
            draft.tags.map(\.entityID),
            [
                UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!
            ])
        XCTAssertEqual(draft.tags.map(\.title), ["Atmospheric"])
        XCTAssertEqual(draft.tags.first?.sourceThumbnail?.kind, .tag)
        XCTAssertEqual(
            draft.studio?.entityID,
            UUID(uuidString: "dddddddd-dddd-dddd-dddd-dddddddddddd")!
        )
        XCTAssertEqual(draft.studio?.sourceThumbnail?.kind, .studio)
        XCTAssertEqual(
            draft.credits.first?.person.entityID,
            UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
        )
        XCTAssertEqual(draft.credits.first?.person.sourceThumbnail?.kind, .person)
        XCTAssertEqual(draft.credits.first?.roles, ["actor", "producer"])
    }

    func testEditDraftKeepsReferencedPeopleWhenExpandedCreditMetadataIsMissing() throws {
        let detail = try makeDetail(creditMetadata: "[]")

        let draft = EntityDetailEditDraft(detail: detail)

        XCTAssertEqual(draft.credits.map(\.person.title), ["Mara Voss"])
        XCTAssertEqual(draft.credits.map(\.roles), [["actor"]])
    }

    func testMainEditRequestSerializesSelectedAndPendingReferencesAtTheWireBoundary() throws {
        let detail = try makeDetail()
        var draft = EntityDetailEditDraft(detail: detail)
        draft.tags.append(.new(title: "Neo-noir", kind: .tag))
        draft.studio = .new(title: "Northstar", kind: .studio)
        draft.credits.append(
            EntityDetailCreditDraft(
                person: .new(title: "Ari Lane", kind: .person),
                roles: [EntityDetailCreditRole.director.rawValue]
            )
        )
        let service = EntityDetailEditService(
            metadataMutator: MetadataMutatorStub(detail: detail),
            userMetadataMutator: nil
        )

        let request = try service.metadataRequest(
            draft: draft,
            detail: detail,
            section: .main
        )

        XCTAssertEqual(request.patch.tags, ["Atmospheric", "Neo-noir"])
        XCTAssertEqual(request.patch.studio, "Northstar")
        XCTAssertTrue(
            request.patch.credits.contains {
                $0.name == "Ari Lane" && $0.role == "director"
            }
        )
    }

    func testMetadataEditRequestKeepsEditableFieldsScopedToMetadata() throws {
        let detail = try makeDetail()
        var draft = EntityDetailEditDraft(detail: detail)
        draft.urls.append(EntityDetailStringDraft(value: "https://example.com/signal"))
        draft.stats = [EntityDetailKeyValueDraft(key: "budget", value: "42")]
        let service = EntityDetailEditService(
            metadataMutator: MetadataMutatorStub(detail: detail),
            userMetadataMutator: nil
        )

        let request = try service.metadataRequest(
            draft: draft,
            detail: detail,
            section: .metadata
        )

        XCTAssertEqual(
            request.fields,
            ["urls", "externalIds", "dates", "stats", "positions", "classification"]
        )
        XCTAssertEqual(request.patch.urls, ["https://example.com/signal"])
        XCTAssertEqual(request.patch.stats, ["budget": 42])
        XCTAssertNil(request.patch.title)
    }

    func testTabbedEditSavePersistsChangesFromMainAndMetadata() async throws {
        let detail = try makeDetail()
        let original = EntityDetailEditDraft(detail: detail)
        var draft = original
        draft.title = "Signal Revised"
        draft.urls.append(EntityDetailStringDraft(value: "https://example.com/signal"))
        let mutator = RecordingMetadataMutatorStub(detail: detail)
        let service = EntityDetailEditService(
            metadataMutator: mutator,
            userMetadataMutator: nil
        )

        let outcome = await service.save(
            draft: draft,
            original: original,
            detail: detail
        )

        XCTAssertEqual(outcome, .saved)
        let requests = await mutator.recordedRequests()
        XCTAssertEqual(requests.count, 2)
        XCTAssertEqual(requests[0].fields, ["title", "description", "tags", "studio", "credits"])
        XCTAssertEqual(
            requests[1].fields,
            ["urls", "externalIds", "dates", "stats", "positions", "classification"]
        )
    }

    func testReferenceSearchUsesATypeFilteredEntityQuery() async throws {
        let personID = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
        let person = EntityThumbnail(
            id: personID,
            kind: .person,
            title: "Mara Voss",
            coverThumbURL: "/mara.jpg"
        )
        let loader = ReferenceSearchLoaderStub(items: [person])
        let service = EntityDetailReferenceSearchService(loader: loader)

        let results = try await service.search(kind: .person, query: "mara")
        let recordedKind = await loader.recordedKind()
        let recordedLimit = await loader.recordedLimit()
        let recordedSearch = await loader.recordedSearch()

        XCTAssertEqual(results.map(\.entityID), [personID])
        XCTAssertEqual(results.map(\.title), ["Mara Voss"])
        XCTAssertEqual(results.first?.sourceThumbnail, person)
        XCTAssertEqual(recordedKind, .person)
        XCTAssertEqual(recordedLimit, 20)
        XCTAssertEqual(recordedSearch, "mara")
    }

    func testReferenceSelectionIgnoresArtworkMetadataChanges() {
        let entityID = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
        let original = EntityDetailReferenceDraft(
            thumbnail: EntityThumbnail(
                id: entityID,
                kind: .person,
                title: "Mara Voss",
                coverThumbURL: "/mara-old.jpg",
                meta: [EntityThumbnailMeta(icon: "person", label: "Actor")]
            )
        )
        let refreshed = EntityDetailReferenceDraft(
            thumbnail: EntityThumbnail(
                id: entityID,
                kind: .person,
                title: "Mara Voss",
                coverThumbURL: "/mara-new.jpg",
                meta: [EntityThumbnailMeta(icon: "film", label: "Director")]
            )
        )

        XCTAssertEqual(original, refreshed)
        XCTAssertEqual(original.hashValue, refreshed.hashValue)
    }

    func testReferenceArtworkRefreshDoesNotMarkEditDraftDirty() throws {
        let detail = try makeDetail()
        let original = EntityDetailEditDraft(detail: detail)
        var refreshed = original
        refreshed.tags = [
            EntityDetailReferenceDraft(
                thumbnail: EntityThumbnail(
                    id: UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!,
                    kind: .tag,
                    title: "Atmospheric",
                    coverThumb2xURL: "/atmospheric@2x.jpg",
                    meta: [EntityThumbnailMeta(icon: "sparkles", label: "Updated artwork")]
                )
            )
        ]

        XCTAssertEqual(original, refreshed)
    }

    func testPendingReferenceIsOfferedOnlyWhenNoExactMatchExists() {
        let existing = EntityDetailReferenceDraft.new(title: "Atmospheric", kind: .tag)

        XCTAssertFalse(
            EntityDetailReferenceSelectionPolicy.canCreate(
                title: " atmospheric ",
                results: [existing],
                selection: []
            )
        )
        XCTAssertFalse(
            EntityDetailReferenceSelectionPolicy.canCreate(
                title: "ATMOSPHERIC",
                results: [],
                selection: [existing]
            )
        )
        XCTAssertTrue(
            EntityDetailReferenceSelectionPolicy.canCreate(
                title: "Neo-noir",
                results: [existing],
                selection: []
            )
        )
    }

    func testEditableEntityKeepsEmptyMetadataTabReachable() throws {
        let detail = try makeDetail(capabilities: "[]", relationships: "[]", creditMetadata: "[]")

        let presentation = EntityDetailPresentation(detail: detail, canEditMetadata: true)

        XCTAssertEqual(Array(presentation.sections.map(\.id).prefix(2)), [.details, .metadata])
        XCTAssertEqual(Array(presentation.sections.map(\.title).prefix(2)), ["Main", "Metadata"])
    }

    func testCreditPresentationUsesCharacterBeforeRole() throws {
        let detail = try makeDetail()

        XCTAssertEqual(
            EntityDetailPresentation(detail: detail).creditSubtitle(
                for: UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
            ),
            "Dr. Hale"
        )
    }

    func testCreditPresentationHumanizesRoleWhenCharacterIsUnavailable() throws {
        let detail = try makeDetail(
            creditMetadata:
                #"[{"personId":"bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb","role":"executive_producer","character":null,"roles":["executive_producer"],"characters":[]}]"#
        )

        XCTAssertEqual(
            EntityDetailPresentation(detail: detail).creditSubtitle(
                for: UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
            ),
            "Executive Producer"
        )
    }

    func testCreditPresentationSuppressesGenericPersonRole() throws {
        let detail = try makeDetail(
            creditMetadata:
                #"[{"personId":"bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb","role":"person","character":null,"roles":["person"],"characters":[]}]"#
        )

        XCTAssertNil(
            EntityDetailPresentation(detail: detail).creditSubtitle(
                for: UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
            )
        )
    }

    func testReverseReferenceQueryEncodesTaxonomyContract() {
        let id = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
        let query = EntityListQuery(referencedBy: id, relationshipCode: "tags")

        let values = Dictionary(
            uniqueKeysWithValues: query.queryItems(limit: 48, search: nil).map {
                ($0.name, $0.value)
            }
        )

        XCTAssertEqual(values["referencedBy"], id.uuidString.lowercased())
        XCTAssertEqual(values["relationshipCode"], "tags")
    }

    func testTaxonomyDetailsUseThePWAsReverseRelationshipMappings() throws {
        let expectations = [
            (kind: "tag", title: "Tagged Content", relationshipCode: "tags"),
            (kind: "person", title: "Appearances", relationshipCode: "cast"),
            (kind: "studio", title: "Content", relationshipCode: "studio"),
        ]

        for expectation in expectations {
            let detail = try makeDetail(
                kind: expectation.kind,
                capabilities: "[]",
                relationships: "[]",
                creditMetadata: "[]"
            )
            let presentation = try XCTUnwrap(
                EntityDetailReferencedContentPresentation(detail: detail)
            )

            XCTAssertEqual(presentation.title, expectation.title)
            XCTAssertEqual(presentation.query.referencedBy, detail.id)
            XCTAssertEqual(presentation.query.relationshipCode, expectation.relationshipCode)
        }
    }

    private func makeDetail(
        kind: String = "movie",
        capabilities: String =
            #"[{"kind":"description","value":"A mystery."},{"kind":"flags","isFavorite":false,"isNsfw":false,"isOrganized":true,"isWanted":false}]"#,
        relationships: String =
            #"[{"kind":"person","label":"Cast","code":"cast","entities":[{"id":"bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb","kind":"person","title":"Mara Voss","hoverImages":[],"meta":[]}]},{"kind":"tag","label":"Tags","code":"tags","entities":[{"id":"cccccccc-cccc-cccc-cccc-cccccccccccc","kind":"tag","title":"Atmospheric","hoverImages":[],"meta":[]}]},{"kind":"studio","label":"Studio","code":"studio","entities":[{"id":"dddddddd-dddd-dddd-dddd-dddddddddddd","kind":"studio","title":"Northlight","hoverImages":[],"meta":[]}]}]"#,
        creditMetadata: String =
            #"[{"personId":"bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb","role":"actor","character":"Dr. Hale","roles":["actor","producer"],"characters":["Dr. Hale","The Witness"]}]"#
    ) throws -> EntityDetail {
        let json = """
            {
              "id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
              "kind": "\(kind)",
              "title": "Signal",
              "parentEntityId": null,
              "sortOrder": null,
              "hasSourceMedia": true,
              "capabilities": \(capabilities),
              "childrenByKind": [],
              "relationships": \(relationships),
              "creditMetadata": \(creditMetadata)
            }
            """
        return try PrismediaJSON.decoder().decode(EntityDetail.self, from: Data(json.utf8))
    }

    private actor MetadataMutatorStub: EntityMetadataMutating {
        let detail: EntityDetail

        init(detail: EntityDetail) {
            self.detail = detail
        }

        func updateMetadata(
            id: UUID,
            kind: EntityKind,
            request: EntityDetailMetadataUpdateRequest
        ) async throws -> EntityDetail {
            detail
        }
    }

    private actor RecordingMetadataMutatorStub: EntityMetadataMutating {
        let detail: EntityDetail
        private var requests: [EntityDetailMetadataUpdateRequest] = []

        init(detail: EntityDetail) {
            self.detail = detail
        }

        func updateMetadata(
            id: UUID,
            kind: EntityKind,
            request: EntityDetailMetadataUpdateRequest
        ) async throws -> EntityDetail {
            requests.append(request)
            return detail
        }

        func recordedRequests() -> [EntityDetailMetadataUpdateRequest] {
            requests
        }
    }

    private actor ReferenceSearchLoaderStub: EntityGridLoading {
        let items: [EntityThumbnail]
        let allowsNsfwContent = true
        private var kind: EntityKind?
        private var limit: Int?
        private var search: String?

        init(items: [EntityThumbnail]) {
            self.items = items
        }

        func load(
            query: EntityListQuery,
            limit: Int,
            search: String?,
            cursor: String?
        ) async throws -> EntityListResponse {
            kind = query.kind
            self.limit = limit
            self.search = search
            return EntityListResponse(items: items)
        }

        func recordedKind() -> EntityKind? { kind }
        func recordedLimit() -> Int? { limit }
        func recordedSearch() -> String? { search }
    }
}
