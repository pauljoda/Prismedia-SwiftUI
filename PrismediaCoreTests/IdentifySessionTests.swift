import XCTest

@testable import PrismediaCore

#if os(iOS) || os(macOS)
    final class IdentifySessionTests: XCTestCase {
        @MainActor
        func testBulkIdentifyDoesNotClaimSkippedItemsSucceeded() async throws {
            let item = try queueItem()
            let items = [
                EntityThumbnail(id: UUID(), kind: .movie, title: "First", hasSourceMedia: true),
                EntityThumbnail(id: UUID(), kind: .movie, title: "Second", hasSourceMedia: true),
            ]
            let providers = [provider(id: "tmdb", name: "Movie provider")]
            for enqueued in [0, 1, 2] {
                let service = OpenIdentifyServiceSpy(
                    item: item,
                    bulkResponse: AdministrativeIdentifyBulkAcceptedResponse(requested: 2, enqueued: enqueued)
                )
                let session = IdentifySession(
                    service: service,
                    browser: IdentifyPreviewEntityBrowser(),
                    initialProviders: providers
                )

                let result = await session.queueBrowseItems(items, kind: .movie, providerID: "tmdb")

                if enqueued == 2 {
                    XCTAssertEqual(result.succeededIDs, Set(items.map(\.id)))
                    XCTAssertTrue(result.failures.isEmpty)
                } else {
                    // Aggregate counts cannot identify which items were skipped.
                    XCTAssertTrue(result.succeededIDs.isEmpty)
                    XCTAssertEqual(Set(result.failures.map(\.entityID)), Set(items.map(\.id)))
                }
            }
        }

        @MainActor
        func testOpeningMissingQueueItemCreatesItWithoutStartingSearch() async throws {
            let item = try queueItem()
            let service = OpenIdentifyServiceSpy(item: item)
            let session = IdentifySession(service: service, browser: IdentifyPreviewEntityBrowser())

            await session.open(entityID: item.entityID)

            let counts = await service.callCounts()
            XCTAssertEqual(counts.get, 1)
            XCTAssertEqual(counts.add, 1)
            XCTAssertEqual(counts.search, 0)
            XCTAssertEqual(session.selectedItemID, item.entityID)
        }

        @MainActor
        func testBackgroundQueueRefreshReconcilesSelectionWithoutAFullLoad() async throws {
            let first = try queueItem(title: "Arrival")
            let second = try queueItem(title: "Dune")
            let service = OpenIdentifyServiceSpy(item: first, queue: [second])
            let session = IdentifySession(
                service: service,
                browser: IdentifyPreviewEntityBrowser(),
                initialQueue: [first]
            )
            session.selectedQueueIDs = [first.entityID, second.entityID]

            await session.refreshQueue()

            XCTAssertEqual(session.queue, [second])
            XCTAssertEqual(session.selectedItemID, second.entityID)
            XCTAssertEqual(session.selectedQueueIDs, [second.entityID])
            XCTAssertFalse(session.isLoading)
        }

        @MainActor
        func testBeginningEntityEntryPersistsQueueAndStartsServerProviderSearch() async throws {
            let item = try queueItem(state: "search")
            let service = OpenIdentifyServiceSpy(item: item)
            let session = IdentifySession(
                service: service,
                browser: IdentifyPreviewEntityBrowser()
            )

            await session.beginEntry(entityID: item.entityID)

            let counts = await service.callCounts()
            let callOrder = await service.callOrder()
            XCTAssertEqual(counts.get, 1)
            XCTAssertEqual(counts.add, 1)
            XCTAssertEqual(counts.search, 1)
            XCTAssertEqual(callOrder, ["get", "add", "search"])
            XCTAssertEqual(session.selectedItemID, item.entityID)
        }

        @MainActor
        func testBeginningEntityEntrySelectsConfiguredProviderForItsKind() async throws {
            let item = try queueItem(state: "search")
            let providers = [
                provider(id: "alpha", name: "Alpha"),
                provider(id: "tmdb", name: "Zulu"),
            ]
            let service = OpenIdentifyServiceSpy(
                item: item,
                providers: providers,
                settingValues: [
                    "identify.defaultProviders": .stringMap(["movie": "tmdb"])
                ]
            )
            let session = IdentifySession(
                service: service,
                browser: IdentifyPreviewEntityBrowser()
            )

            await session.beginEntry(entityID: item.entityID)

            XCTAssertEqual(session.selectedProviderID, "tmdb")
            XCTAssertEqual(session.providersForSelectedItem.map(\.id), ["tmdb", "alpha"])
        }

        @MainActor
        func testBeginningExistingEntryRestoresQueuedProviderAndQueryFieldsBeforeDefault() async throws {
            let item = try queueItem(
                state: "search",
                providerID: "alpha",
                queryFields: ["title": "Restored title"]
            )
            let providers = [
                provider(id: "alpha", name: "Alpha"),
                provider(id: "tmdb", name: "Zulu"),
            ]
            let service = OpenIdentifyServiceSpy(
                item: item,
                getItems: [item],
                providers: providers,
                settingValues: [
                    "identify.defaultProviders": .stringMap(["movie": "tmdb"])
                ]
            )
            let session = IdentifySession(
                service: service,
                browser: IdentifyPreviewEntityBrowser()
            )

            await session.beginEntry(entityID: item.entityID)

            let counts = await service.callCounts()
            XCTAssertEqual(counts.add, 0)
            XCTAssertEqual(counts.search, 0)
            XCTAssertEqual(session.selectedProviderID, "alpha")
            XCTAssertEqual(session.searchValues["title"], "Restored title")
        }

        @MainActor
        func testProviderDraftsAreRetainedWhenSwitchingAwayAndBack() async throws {
            let item = try queueItem(
                state: "search",
                providerID: "alpha",
                queryFields: ["title": "Arrival"]
            )
            let session = IdentifySession(
                service: OpenIdentifyServiceSpy(item: item),
                browser: IdentifyPreviewEntityBrowser(),
                initialQueue: [item],
                initialProviders: [
                    provider(id: "alpha", name: "Alpha"),
                    provider(id: "tmdb", name: "TMDB"),
                ]
            )

            session.searchValues["title"] = "Alpha draft"
            session.selectProvider("tmdb")
            session.searchValues["title"] = "TMDB draft"
            session.selectProvider("alpha")

            XCTAssertEqual(session.searchValues["title"], "Alpha draft")
        }

        @MainActor
        func testProviderSwitchHidesCandidatesFromThePreviousProvider() throws {
            let item = try queueItem(
                state: "search",
                providerID: "alpha",
                candidates: [
                    AdministrativeEntitySearchCandidate(
                        externalIDs: ["alpha": "arrival"],
                        title: "Arrival",
                        candidateID: "arrival",
                        source: "alpha"
                    )
                ]
            )
            let session = IdentifySession(
                service: OpenIdentifyServiceSpy(item: item),
                browser: IdentifyPreviewEntityBrowser(),
                initialQueue: [item],
                initialProviders: [
                    provider(id: "alpha", name: "Alpha"),
                    provider(id: "tmdb", name: "TMDB"),
                ]
            )

            XCTAssertEqual(session.searchCandidates(for: item).map(\.title), ["Arrival"])

            session.selectProvider("tmdb")

            XCTAssertTrue(session.searchCandidates(for: item).isEmpty)

            session.selectProvider("alpha")

            XCTAssertEqual(session.searchCandidates(for: item).map(\.title), ["Arrival"])
        }

        @MainActor
        func testRefreshingStableProposalSelectsNewlyStreamedChildFields() async throws {
            let root = proposal(id: "root", title: "Series", description: "Root description")
            let initial = try queueItem(state: "proposal", proposal: root)
            let child = proposal(id: "episode-1", title: "Episode 1", description: "Child description")
            let refreshedRoot = proposal(
                id: "root",
                title: "Series",
                description: "Root description",
                children: [child]
            )
            let refreshed = try queueItem(
                entityID: initial.entityID,
                state: "proposal",
                proposal: refreshedRoot
            )
            let service = OpenIdentifyServiceSpy(
                item: initial,
                getItems: [refreshed]
            )
            let session = IdentifySession(
                service: service,
                browser: IdentifyPreviewEntityBrowser(),
                initialQueue: [initial]
            )
            session.reviewSelection.selectedFieldsByProposal["root"]?.remove(.description)

            await session.refreshSelectedItem()

            XCTAssertFalse(
                session.reviewSelection.selectedFieldsByProposal["root"]?.contains(.description) == true
            )
            XCTAssertTrue(
                session.reviewSelection.selectedFieldsByProposal["episode-1"]?.contains(.title) == true
            )
            XCTAssertTrue(
                session.reviewSelection.selectedFieldsByProposal["episode-1"]?.contains(.description) == true
            )
        }

        @MainActor
        func testReopeningReviewRetainsUserChoices() async throws {
            let root = proposal(id: "root", title: "Arrival", description: "Description")
            let item = try queueItem(state: "proposal", proposal: root)
            let session = IdentifySession(
                service: OpenIdentifyServiceSpy(item: item, getItems: [item]),
                browser: IdentifyPreviewEntityBrowser(), initialQueue: [item]
            )
            session.reviewSelection.selectedFieldsByProposal["root"]?.remove(.title)
            let choices = session.reviewSelection

            await session.open(entityID: item.entityID)

            XCTAssertEqual(session.reviewSelection, choices)
        }

        @MainActor
        func testMovingBetweenReviewsKeepsIndependentChoices() throws {
            let first = try queueItem(
                state: "proposal", proposal: proposal(id: "first", title: "Arrival", description: "First")
            )
            let second = try queueItem(
                state: "proposal", proposal: proposal(id: "second", title: "Dune", description: "Second")
            )
            let session = IdentifySession(
                service: OpenIdentifyServiceSpy(item: first),
                browser: IdentifyPreviewEntityBrowser(), initialQueue: [first, second]
            )
            session.reviewSelection.selectedFieldsByProposal["first"]?.remove(.title)
            let firstChoices = session.reviewSelection
            session.selectNext()
            session.reviewSelection.selectedFieldsByProposal["second"]?.remove(.description)
            let secondChoices = session.reviewSelection

            session.selectPrevious()
            XCTAssertEqual(session.selectedItemID, first.entityID)
            XCTAssertEqual(session.reviewSelection, firstChoices)
            session.selectNext()
            XCTAssertEqual(session.selectedItemID, second.entityID)
            XCTAssertEqual(session.reviewSelection, secondChoices)
        }

        @MainActor
        func testReturningToStreamedReviewKeepsChoicesAndIncludesNewChildren() async throws {
            let root = proposal(id: "root", title: "Series", description: "Description")
            let first = try queueItem(state: "proposal", proposal: root)
            let second = try queueItem(
                state: "proposal", proposal: proposal(id: "other", title: "Other", description: nil)
            )
            let updated = try queueItem(
                entityID: first.entityID, state: "proposal",
                proposal: proposal(
                    id: "root", title: "Series", description: "Description",
                    children: [proposal(id: "child", title: "Episode", description: nil)]
                )
            )
            let session = IdentifySession(
                service: OpenIdentifyServiceSpy(item: first, queue: [updated, second]),
                browser: IdentifyPreviewEntityBrowser(), initialQueue: [first, second]
            )
            session.reviewSelection.selectedFieldsByProposal["root"]?.remove(.title)
            session.selectNext()

            await session.refreshQueue()
            session.selectPrevious()

            XCTAssertFalse(session.reviewSelection.selectedFieldsByProposal["root"]?.contains(.title) == true)
            XCTAssertTrue(session.reviewSelection.selectedFieldsByProposal["child"]?.contains(.title) == true)
        }

        @MainActor
        func testReopeningNewProposalStartsWithItsDefaults() async throws {
            let first = try queueItem(
                state: "proposal", proposal: proposal(id: "first", title: "Arrival", description: "First")
            )
            let replacement = proposal(id: "replacement", title: "Arrival", description: "Replacement")
            let updated = try queueItem(entityID: first.entityID, state: "proposal", proposal: replacement)
            let session = IdentifySession(
                service: OpenIdentifyServiceSpy(item: first, getItems: [updated]),
                browser: IdentifyPreviewEntityBrowser(), initialQueue: [first]
            )
            session.reviewSelection.selectedFieldsByProposal["first"]?.remove(.title)

            await session.open(entityID: first.entityID)

            XCTAssertEqual(session.reviewSelection, MetadataReviewPolicy.seededSelection(for: replacement))
        }

        @MainActor
        func testReloadingQueueKeepsChoicesForTheSameProposal() async throws {
            let root = proposal(id: "root", title: "Arrival", description: "Description")
            let item = try queueItem(state: "proposal", proposal: root)
            let session = IdentifySession(
                service: OpenIdentifyServiceSpy(item: item, queue: [item]),
                browser: IdentifyPreviewEntityBrowser(), initialQueue: [item]
            )
            session.reviewSelection.selectedFieldsByProposal["root"]?.remove(.title)
            let choices = session.reviewSelection

            await session.load()

            XCTAssertEqual(session.reviewSelection, choices)
        }

        @MainActor
        func testRemovedQueueItemDoesNotRestoreAnOldDraftWhenReadded() async throws {
            let root = proposal(id: "root", title: "Arrival", description: "Description")
            let item = try queueItem(state: "proposal", proposal: root)
            let session = IdentifySession(
                service: OpenIdentifyServiceSpy(item: item, getItems: [item]),
                browser: IdentifyPreviewEntityBrowser(), initialQueue: [item]
            )
            session.reviewSelection.selectedFieldsByProposal["root"]?.remove(.title)

            await session.refreshQueue()
            await session.open(entityID: item.entityID)

            XCTAssertEqual(session.reviewSelection, MetadataReviewPolicy.seededSelection(for: root))
        }

        private func queueItem(
            entityID: UUID = UUID(),
            title: String = "Arrival",
            state: String = "queued",
            providerID: String? = nil,
            queryFields: [String: String]? = nil,
            candidates: [AdministrativeEntitySearchCandidate] = [],
            proposal: AdministrativeEntityMetadataProposal? = nil
        ) throws -> AdministrativeIdentifyQueueItem {
            let id = UUID()
            var object: [String: Any] = [
                "id": id.uuidString,
                "entityId": entityID.uuidString,
                "entityKind": "movie",
                "title": title,
                "isNsfw": false,
                "state": state,
                "action": "identify",
                "candidates": try JSONSerialization.jsonObject(
                    with: JSONEncoder().encode(candidates)
                ),
                "cascadeRunning": false,
                "createdAt": "2026-07-12T12:00:00Z",
                "updatedAt": "2026-07-12T12:00:00Z",
            ]
            object["provider"] = providerID
            if let queryFields {
                object["query"] = try JSONSerialization.jsonObject(
                    with: JSONEncoder().encode(
                        AdministrativeIdentifyQuery(
                            title: queryFields["title"],
                            requireChoice: true,
                            fields: queryFields,
                            limit: 25
                        )
                    )
                )
            }
            if let proposal {
                object["proposal"] = try JSONSerialization.jsonObject(
                    with: JSONEncoder().encode(proposal)
                )
            }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(
                AdministrativeIdentifyQueueItem.self,
                from: JSONSerialization.data(withJSONObject: object)
            )
        }

        private func proposal(
            id: String,
            title: String,
            description: String?,
            children: [AdministrativeEntityMetadataProposal] = []
        ) -> AdministrativeEntityMetadataProposal {
            AdministrativeEntityMetadataProposal(
                proposalID: id,
                provider: "tmdb",
                targetKind: .movie,
                confidence: 1,
                matchReason: "test",
                patch: AdministrativeEntityMetadataPatch(
                    title: title,
                    description: description,
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
                relationships: []
            )
        }

        private func provider(id: String, name: String) -> AdministrativePlugin {
            AdministrativePlugin(
                id: id,
                name: name,
                version: "1",
                installed: true,
                enabled: true,
                isNsfw: false,
                supports: [
                    AdministrativePluginSupport(
                        entityKind: "movie",
                        actions: ["search", "lookup-id"],
                        search: AdministrativePluginSearchDefinition(fields: [
                            AdministrativePluginSearchField(
                                key: "title",
                                label: "Title",
                                type: "text",
                                required: true,
                                placeholder: nil,
                                help: nil
                            )
                        ])
                    )
                ],
                missingAuthKeys: [],
                updateAvailable: false,
                availableVersion: nil
            )
        }
    }
#endif
