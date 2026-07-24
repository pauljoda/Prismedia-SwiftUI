import XCTest

@testable import PrismediaCore

#if os(iOS) || os(macOS)
    final class IdentifySessionTests: XCTestCase {
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
                targetKind: "movie",
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
