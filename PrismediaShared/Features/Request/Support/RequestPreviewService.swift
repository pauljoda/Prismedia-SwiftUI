import Foundation

#if DEBUG
    struct RequestPreviewService: RequestFeatureServicing {
        let scenario: RequestPreviewScenario

        func providers() async throws -> [AdministrativePlugin] {
            switch scenario {
            case .loading:
                try await Task.sleep(for: .seconds(60))
                return []
            case .empty:
                return []
            case .error:
                throw URLError(.cannotConnectToHost)
            case .content:
                return [provider]
            }
        }

        func search(
            kind: String,
            pluginID: String,
            fields: [String: String]
        ) async throws -> AdministrativeRequestSearchResponse {
            AdministrativeRequestSearchResponse(results: [result], providerErrors: [])
        }

        func review(
            kind: String,
            pluginID: String,
            externalIdentity: AdministrativeExternalIdentity
        ) async throws -> AdministrativeRequestReviewResponse {
            let root = proposal(id: "movie-root", kind: "movie", title: "The Arrival")
            return AdministrativeRequestReviewResponse(
                pluginID: pluginID,
                externalIdentity: externalIdentity,
                entityKind: .movie,
                kind: kind,
                proposal: root,
                revision: "preview-revision",
                targets: [
                    AdministrativeRequestReviewTarget(
                        proposalID: root.proposalID,
                        kind: kind,
                        entityKind: .movie,
                        externalIdentity: externalIdentity,
                        requestable: true,
                        position: nil,
                        year: 2016,
                        monitored: nil
                    )
                ]
            )
        }

        func commit(
            _ request: AdministrativeReviewedRequestCommitRequest
        ) async throws -> AdministrativeRequestCommitResponse {
            AdministrativeRequestCommitResponse(
                containerEntityID: nil,
                items: [
                    AdministrativeRequestCommitItem(
                        externalID: "tmdb:329865",
                        title: "The Arrival",
                        outcome: "requested",
                        entityID: UUID(uuidString: "11111111-1111-1111-1111-111111111111"),
                        acquisitionID: UUID(uuidString: "22222222-2222-2222-2222-222222222222")
                    )
                ]
            )
        }

        func libraryRoots() async throws -> [AdministrativeLibraryRoot] {
            [
                AdministrativeLibraryRoot(
                    id: rootID,
                    path: "/media/movies",
                    label: "Movies",
                    enabled: true,
                    scanVideos: true
                )
            ]
        }

        func acquisitionProfiles() async throws -> [AdministrativeAcquisitionProfile] {
            [
                AdministrativeAcquisitionProfile(
                    id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
                    kind: .movie,
                    displayName: "Movie HD",
                    isDefault: true,
                    targetLibraryRootID: rootID
                )
            ]
        }

        private var rootID: UUID {
            UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        }

        private var provider: AdministrativePlugin {
            AdministrativePlugin(
                id: "tmdb",
                name: "The Movie Database",
                version: "1.0.0",
                installed: true,
                enabled: true,
                isNsfw: false,
                supports: [
                    AdministrativePluginSupport(
                        entityKind: "movie",
                        actions: ["search", "lookup-id"],
                        identityNamespaces: ["tmdb"],
                        search: AdministrativePluginSearchDefinition(fields: [
                            AdministrativePluginSearchField(
                                key: "query",
                                label: "Title",
                                type: "text",
                                required: true,
                                placeholder: "Search movies",
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

        private var result: AdministrativeRequestSearchResult {
            AdministrativeRequestSearchResult(
                serviceID: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
                source: "plugin",
                kind: "movie",
                externalID: "tmdb:329865",
                title: "The Arrival",
                subtitle: "2016 film",
                year: 2016,
                overview: "A linguist works to communicate with visitors from another world.",
                posterURL: nil,
                backdropURL: nil,
                rating: 8.0,
                runtimeMinutes: 116,
                certification: "PG-13",
                trackCount: nil,
                tags: ["Science Fiction"],
                tracked: false,
                upstreamID: "329865",
                monitored: nil,
                requestable: true,
                providerName: "The Movie Database",
                pluginID: "tmdb",
                externalIdentity: AdministrativeExternalIdentity(namespace: "tmdb", value: "329865")
            )
        }

        private func proposal(id: String, kind: String, title: String) -> AdministrativeEntityMetadataProposal {
            AdministrativeEntityMetadataProposal(
                proposalID: id,
                provider: "tmdb",
                targetKind: kind,
                confidence: 0.98,
                matchReason: "Exact title and year",
                patch: AdministrativeEntityMetadataPatch(
                    title: title,
                    description: "A canonical preview proposal.",
                    externalIDs: ["tmdb": "329865"],
                    urls: [],
                    tags: ["Science Fiction"],
                    studio: nil,
                    credits: [],
                    dates: ["release": "2016-11-11"],
                    stats: [:],
                    positions: [:],
                    classification: "PG-13",
                    rating: 8,
                    flags: nil
                ),
                images: [],
                children: [],
                candidates: [],
                targetEntityID: nil,
                relationships: []
            )
        }
    }
#endif
