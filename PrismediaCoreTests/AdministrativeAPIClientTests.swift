import XCTest

@testable import PrismediaCore

final class AdministrativeAPIClientTests: XCTestCase {
    private let serverURL = URL(string: "https://media.example.test")!

    private func queryItem(_ name: String, in request: URLRequest) -> String? {
        URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == name })?
            .value
    }

    func testFilesLoadAndRescanUseExactAdminContracts() async throws {
        let rootID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let loader = MockHTTPDataLoader(responses: [
            .json(#"{"roots":[{"id":"\#(rootID)","label":"Movies","path":"/media/movies","enabled":true}]}"#),
            .json(#"{"rootId":"\#(rootID)","path":"","entries":[]}"#),
            .json(#"{"scansQueued":1}"#),
        ])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "token", loader: loader)

        let roots = try await client.listAdministrativeFileRoots()
        _ = try await client.listAdministrativeFileChildren(rootID: rootID, path: "")
        let response = try await client.rescanAdministrativeFiles(rootID: rootID, path: "Season 1")

        XCTAssertEqual(roots.first?.label, "Movies")
        XCTAssertEqual(response.scansQueued, 1)
        XCTAssertEqual(loader.requests[0].url?.path, "/api/files/roots")
        XCTAssertEqual(queryItem("hideNsfw", in: loader.requests[0]), "true")
        XCTAssertEqual(loader.requests[1].url?.path, "/api/files/children")
        XCTAssertEqual(queryItem("rootId", in: loader.requests[1]), rootID.uuidString.lowercased())
        XCTAssertEqual(queryItem("path", in: loader.requests[1]), "")
        XCTAssertEqual(queryItem("hideNsfw", in: loader.requests[1]), "true")
        XCTAssertEqual(loader.requests[2].url?.path, "/api/files/rescan")
        XCTAssertEqual(loader.requests[2].httpMethod, "POST")
        let body = try XCTUnwrap(
            JSONSerialization.jsonObject(with: XCTUnwrap(loader.requests[2].httpBody)) as? [String: Any])
        XCTAssertEqual(body["rootId"] as? String, rootID.uuidString)
        XCTAssertEqual(body["path"] as? String, "Season 1")
    }

    func testRequestSearchPostsPluginOwnedFields() async throws {
        let loader = MockHTTPDataLoader(responses: [
            .json(
                #"{"results":[{"serviceId":"10101010-1010-1010-1010-101010101010","source":"plugin","kind":"movie","externalId":"tmdb:603","title":"The Matrix","subtitle":"1999 film","year":1999,"overview":"A simulation.","posterUrl":"https://image.example/poster.jpg","backdropUrl":"https://image.example/backdrop.jpg","rating":8.7,"runtimeMinutes":136,"certification":"R","trackCount":null,"tags":["Science Fiction"],"tracked":false,"upstreamId":"603","monitored":null,"requestable":true,"providerName":"TMDB","pluginId":"tmdb","externalIdentity":{"namespace":"tmdb","value":"603"}}],"providerErrors":[]}"#
            )
        ])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "token", loader: loader)

        let response = try await client.searchAdministrativeRequests(
            kind: "movie",
            pluginID: "tmdb",
            fields: ["query": "Arrival"]
        )

        XCTAssertEqual(response.results.first?.externalIdentity?.value, "603")
        XCTAssertEqual(response.results.first?.backdropURL, "https://image.example/backdrop.jpg")
        XCTAssertEqual(response.results.first?.runtimeMinutes, 136)
        XCTAssertEqual(response.results.first?.tags, ["Science Fiction"])
        let request = try XCTUnwrap(loader.requests.first)
        XCTAssertEqual(request.url?.path, "/api/requests/search")
        XCTAssertEqual(request.httpMethod, "POST")
        let body = try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(request.httpBody)) as? [String: Any])
        XCTAssertEqual(body["kind"] as? String, "movie")
        XCTAssertEqual(body["pluginId"] as? String, "tmdb")
        XCTAssertEqual((body["fields"] as? [String: String])?["query"], "Arrival")
    }

    func testPluginUpdateUsesProviderRoute() async throws {
        let provider =
            #"{"id":"tmdb","name":"TMDB","version":"1.0.0","installed":true,"enabled":true,"isNsfw":false,"supports":[],"auth":[],"missingAuthKeys":[],"updateAvailable":false,"availableVersion":null}"#
        let loader = MockHTTPDataLoader(responses: [.json("[\(provider)]"), .json(provider)])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "token", loader: loader)

        _ = try await client.listAdministrativePlugins()
        _ = try await client.updateAdministrativePlugin(id: "tmdb")

        XCTAssertEqual(loader.requests[0].url?.path, "/api/plugins")
        XCTAssertEqual(loader.requests[1].url?.path, "/api/plugins/tmdb/update")
        XCTAssertEqual(loader.requests[1].httpMethod, "POST")
    }

    func testJobActionsUseExactMaintenanceContracts() async throws {
        let loader = MockHTTPDataLoader(responses: [
            .json(#"{"items":[],"counts":[]}"#),
            .json(#"{"cancelled":2}"#),
            .json(#"{"cleared":3}"#),
            .json(#"{"enqueued":4,"skipped":1}"#),
        ])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "token", loader: loader)

        _ = try await client.listAdministrativeJobs()
        _ = try await client.cancelAdministrativeJobs(type: "scan")
        _ = try await client.clearAdministrativeJobFailures(type: "scan")
        _ = try await client.rebuildAdministrativePreviews()

        XCTAssertEqual(loader.requests[1].httpMethod, "DELETE")
        XCTAssertEqual(queryItem("type", in: loader.requests[1]), "scan")
        XCTAssertEqual(loader.requests[2].url?.path, "/api/jobs/failures/clear")
        XCTAssertEqual(loader.requests[2].httpMethod, "POST")
        XCTAssertEqual(loader.requests[3].url?.path, "/api/jobs/rebuild-previews")
    }

    func testSettingsScalarUpdateCacheClearAndBackupUseExactContracts() async throws {
        let descriptor =
            #"{"key":"scan.intervalMinutes","groupKey":"library","label":"Scan interval","description":"Minutes between scans","type":"number","value":30,"defaultValue":60,"isDefault":false,"order":1,"constraints":null,"options":[],"inputKind":null,"applyHint":null}"#
        let loader = MockHTTPDataLoader(responses: [
            .json(
                "{\"groups\":[{\"key\":\"library\",\"label\":\"Library\",\"description\":\"Scanning\",\"order\":1,\"settings\":[\(descriptor)]}]}"
            ),
            .json(descriptor),
            .json(#"{"usedBytes":0,"maxBytes":1000}"#),
            .json(
                #"{"id":"44444444-4444-4444-4444-444444444444","fileName":"manual.sql","backupPath":"/data/manual.sql","status":"complete","isManual":true,"sizeBytes":10,"createdAt":"2026-07-11T12:00:00Z","completedAt":"2026-07-11T12:00:01Z","expiresAt":null,"error":null}"#
            ),
        ])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "token", loader: loader)

        _ = try await client.loadAdministrativeSettings()
        _ = try await client.updateAdministrativeSetting(key: "scan.intervalMinutes", value: .number(45))
        _ = try await client.clearAdministrativeTranscodeCache()
        _ = try await client.createAdministrativeDatabaseBackup()

        XCTAssertEqual(loader.requests[1].url?.path, "/api/settings/scan.intervalMinutes")
        XCTAssertEqual(loader.requests[1].httpMethod, "PATCH")
        let body = try XCTUnwrap(
            JSONSerialization.jsonObject(with: XCTUnwrap(loader.requests[1].httpBody)) as? [String: Any])
        XCTAssertEqual(body["value"] as? Int, 45)
        XCTAssertEqual(loader.requests[2].url?.path, "/api/settings/transcode-cache/clear")
        XCTAssertEqual(loader.requests[3].url?.path, "/api/settings/database-backups/now")
    }

    func testRequestReviewAndCommitUseCanonicalProposalContracts() async throws {
        let entityID = UUID(uuidString: "55555555-5555-5555-5555-555555555555")!
        let acquisitionID = UUID(uuidString: "66666666-6666-6666-6666-666666666666")!
        let loader = MockHTTPDataLoader(responses: [
            .json(requestReviewJSON),
            .json(requestReviewJSON),
            .json(
                #"{"containerEntityId":null,"items":[{"externalId":"tmdb:603","title":"The Matrix","outcome":"requested","entityId":"\#(entityID)","acquisitionId":"\#(acquisitionID)"}]}"#
            ),
        ])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "token", loader: loader)
        let identity = AdministrativeExternalIdentity(namespace: "tmdb", value: "603")

        let review = try await client.reviewAdministrativeRequest(
            kind: "movie",
            pluginID: "tmdb",
            externalIdentity: identity
        )
        _ = try await client.reviewAdministrativeEntityRequest(entityID: entityID, kind: "movie")
        let result = try await client.commitAdministrativeReviewedRequest(
            AdministrativeReviewedRequestCommitRequest(
                kind: "movie",
                pluginID: "tmdb",
                rootExternalIdentity: identity,
                proposalRevision: review.revision,
                selectedProposalIDs: ["movie-603"],
                targetLibraryRootID: nil,
                profileID: nil,
                preset: nil
            ))

        XCTAssertEqual(review.proposal.patch.title, "The Matrix")
        XCTAssertEqual(review.targets.first?.externalIdentity, identity)
        XCTAssertEqual(result.items.first?.entityID, entityID)
        XCTAssertEqual(
            loader.requests.map(\.url?.path),
            ["/api/requests/review", "/api/requests/review-entity", "/api/requests/commit-reviewed"]
        )
        XCTAssertTrue(loader.requests.allSatisfy { queryItem("hideNsfw", in: $0) == "true" })
        let reviewBody = try jsonBody(loader.requests[0])
        XCTAssertEqual(reviewBody["pluginId"] as? String, "tmdb")
        XCTAssertEqual((reviewBody["externalIdentity"] as? [String: String])?["value"], "603")
        let entityReviewBody = try jsonBody(loader.requests[1])
        XCTAssertEqual(entityReviewBody["entityId"] as? String, entityID.uuidString)
        let commitBody = try jsonBody(loader.requests[2])
        XCTAssertEqual(commitBody["selectedProposalIds"] as? [String], ["movie-603"])
        XCTAssertEqual(commitBody["proposalRevision"] as? String, "revision-1")
    }

    func testRequestTargetLookupsUseExactContractsAndDecodeFullShapes() async throws {
        let rootID = UUID(uuidString: "77777777-7777-7777-7777-777777777777")!
        let profileID = UUID(uuidString: "88888888-8888-8888-8888-888888888888")!
        let loader = MockHTTPDataLoader(responses: [
            .json(
                #"[{"id":"\#(rootID)","path":"/media/movies","label":"Movies","enabled":true,"recursive":true,"scanVideos":true,"scanImages":false,"scanAudio":false,"scanBooks":false,"isNsfw":false,"lastScannedAt":null,"createdAt":"2026-07-12T12:00:00Z","updatedAt":"2026-07-12T12:00:00Z","autoIdentify":true,"createdByUserId":null,"accessUserIds":[]}]"#
            ),
            .json(
                #"[{"id":"\#(profileID)","kind":"movie","displayName":"Movie HD","isDefault":true,"targetLibraryRootId":"\#(rootID)","pathTemplate":"{Title} ({Year})","importMode":"copy","allowedFormats":[],"preferredLanguages":["en"],"minSeeders":1,"minSizeBytes":null,"maxSizeBytes":null,"requiredTerms":[],"ignoredTerms":[],"preferredTerms":[],"weightedTerms":[{"term":"remux","weight":100}],"autoPick":true,"autoRedownload":false,"upgradeUntilCutoff":true,"cutoffSourceTier":"bluray","cutoffFormatTier":"epub","downloadCategory":"movies","allowedQualities":["1080p"],"cutoffQuality":"1080p","formatScores":{"remux":100},"minFormatScore":0,"cutoffFormatScore":100}]"#
            ),
        ])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "token", loader: loader)

        let roots = try await client.listAdministrativeLibraryRoots()
        let profiles = try await client.listAdministrativeAcquisitionProfiles()

        XCTAssertEqual(roots.first?.id, rootID)
        XCTAssertEqual(roots.first?.scanVideos, true)
        XCTAssertEqual(profiles.first?.id, profileID)
        XCTAssertEqual(profiles.first?.targetLibraryRootID, rootID)
        XCTAssertEqual(profiles.first?.weightedTerms.first?.weight, 100)
        XCTAssertEqual(loader.requests.map(\.url?.path), ["/api/libraries", "/api/acquisitions/profiles"])
        XCTAssertTrue(loader.requests.allSatisfy { $0.httpMethod == "GET" })
    }

    func testIdentifyQueueMutationsUseExactRoutesBodiesAndVisibility() async throws {
        let entityID = UUID(uuidString: "77777777-7777-7777-7777-777777777777")!
        let progressID = UUID(uuidString: "88888888-8888-8888-8888-888888888888")!
        let loader = MockHTTPDataLoader(responses: [
            .json("[\(pluginJSON)]"),
            .json(identifyQueueItemJSON(entityID: entityID, state: "queued")),
            .json(identifyQueueItemJSON(entityID: entityID, state: "queued")),
            .json(identifyQueueItemJSON(entityID: entityID, state: "proposal")),
            .json(identifyQueueItemJSON(entityID: entityID, state: "proposal")),
            .json(identifyQueueItemJSON(entityID: entityID, state: "done")),
            .json(identifyQueueItemJSON(entityID: entityID, state: "proposal")),
            .json(
                #"{"id":"\#(progressID)","entityId":"\#(entityID)","state":"running","currentIndex":1,"total":2,"currentKind":"movie","currentTitle":"The Matrix","currentPath":["The Matrix"],"error":null,"updatedAt":"2026-07-12T12:00:00Z"}"#
            ),
            .json(identifyQueueItemJSON(entityID: entityID, state: "deleted")),
        ])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "token", loader: loader)

        _ = try await client.listAdministrativeIdentifyProviders(kind: "movie")
        _ = try await client.addAdministrativeIdentifyQueueItem(entityID: entityID)
        _ = try await client.getAdministrativeIdentifyQueueItem(entityID: entityID)
        _ = try await client.searchAdministrativeIdentifyQueueItem(
            entityID: entityID,
            provider: "tmdb",
            query: AdministrativeIdentifyQuery(title: "Matrix", requireChoice: true)
        )
        let candidate = AdministrativeEntitySearchCandidate(
            externalIDs: ["tmdb": "603"], title: "The Matrix", candidateID: "603", source: "tmdb")
        let resolved = try await client.resolveAdministrativeIdentifyQueueCandidate(
            entityID: entityID, provider: "tmdb", candidate: candidate)
        _ = try await client.applyAdministrativeIdentifyQueueItem(
            entityID: entityID,
            proposal: resolved.proposal,
            selectedFields: ["title", "externalIds"],
            selectedImages: ["poster": "https://image.example/poster.jpg"],
            progressID: progressID
        )
        _ = try await client.saveAdministrativeIdentifyQueueProposal(
            entityID: entityID, proposal: try XCTUnwrap(resolved.proposal))
        let progress = try await client.administrativeIdentifyApplyProgress(
            entityID: entityID, progressID: progressID)
        _ = try await client.removeAdministrativeIdentifyQueueItem(entityID: entityID)

        XCTAssertEqual(progress.currentTitle, "The Matrix")
        XCTAssertEqual(loader.requests[0].url?.path, "/api/identify/providers")
        XCTAssertEqual(queryItem("kind", in: loader.requests[0]), "movie")
        XCTAssertEqual(loader.requests[1].httpMethod, "POST")
        XCTAssertEqual(loader.requests[2].httpMethod, "GET")
        XCTAssertEqual(
            loader.requests[3].url?.path, "/api/identify/queue/entities/\(entityID.uuidString.lowercased())/search")
        XCTAssertEqual(queryItem("hideNsfw", in: loader.requests[3]), "true")
        XCTAssertEqual(
            loader.requests[4].url?.path, "/api/identify/queue/entities/\(entityID.uuidString.lowercased())/candidate")
        XCTAssertEqual(loader.requests[6].httpMethod, "PUT")
        XCTAssertEqual(
            loader.requests[7].url?.path,
            "/api/identify/queue/entities/\(entityID.uuidString.lowercased())/apply-progress/\(progressID.uuidString.lowercased())"
        )
        let searchBody = try jsonBody(loader.requests[3])
        XCTAssertEqual(searchBody["provider"] as? String, "tmdb")
        XCTAssertEqual((searchBody["query"] as? [String: Any])?["requireChoice"] as? Bool, true)
        let applyBody = try jsonBody(loader.requests[5])
        XCTAssertEqual(applyBody["progressId"] as? String, progressID.uuidString)
    }

    func testTransientAndBulkIdentifyUseExactContracts() async throws {
        let entityID = UUID(uuidString: "99999999-9999-9999-9999-999999999999")!
        let loader = MockHTTPDataLoader(responses: [
            .json(proposalJSON),
            .json("", statusCode: 204),
            .json(#"{"requested":1,"enqueued":1}"#, statusCode: 202),
        ])
        let client = PrismediaAPIClient(
            serverURL: serverURL,
            accessToken: "token",
            allowsNsfwContent: true,
            loader: loader
        )

        let proposal = try await client.identifyAdministrativeEntity(
            entityID: entityID,
            provider: "tmdb",
            query: AdministrativeIdentifyQuery(title: "Matrix"),
            parentExternalIDs: nil
        )
        try await client.applyAdministrativeIdentifyProposal(
            entityID: entityID,
            proposal: proposal,
            selectedFields: ["title"],
            selectedImages: [:]
        )
        let accepted = try await client.startAdministrativeBulkIdentify(
            provider: "tmdb", entityIDs: [entityID], query: nil)

        XCTAssertEqual(accepted.requested, 1)
        XCTAssertEqual(loader.requests[0].url?.path, "/api/identify/entities/\(entityID.uuidString.lowercased())")
        XCTAssertEqual(queryItem("hideNsfw", in: loader.requests[0]), "false")
        XCTAssertEqual(loader.requests[1].url?.path, "/api/identify/entities/\(entityID.uuidString.lowercased())/apply")
        XCTAssertEqual(loader.requests[2].url?.path, "/api/identify/bulk")
        XCTAssertEqual(queryItem("hideNsfw", in: loader.requests[2]), "false")
    }

    private func jsonBody(_ request: URLRequest) throws -> [String: Any] {
        try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(request.httpBody)) as? [String: Any])
    }

    private var pluginJSON: String {
        #"{"id":"tmdb","name":"TMDB","version":"1.0.0","installed":true,"enabled":true,"isNsfw":false,"supports":[{"entityKind":"movie","actions":["search"],"identityNamespaces":["tmdb"],"search":{"fields":[{"key":"title","label":"Title","type":"text","required":true,"placeholder":null,"help":null}]},"identityUrls":[]}],"auth":[],"missingAuthKeys":[],"updateAvailable":false,"availableVersion":null}"#
    }

    private var proposalJSON: String {
        #"{"proposalId":"movie-603","provider":"tmdb","targetKind":"movie","confidence":0.99,"matchReason":"id","patch":{"title":"The Matrix","description":"A simulation.","externalIds":{"tmdb":"603"},"urls":[],"tags":["Science Fiction"],"studio":null,"credits":[],"dates":{"released":"1999-03-31"},"stats":{"runtimeMinutes":136},"positions":{},"classification":"R","rating":null,"flags":{"isFavorite":null,"isNsfw":false,"isOrganized":null}},"images":[{"kind":"poster","url":"https://image.example/poster.jpg","source":"tmdb","rank":1,"language":"en","width":1000,"height":1500}],"children":[],"candidates":[],"targetEntityId":null,"relationships":[]}"#
    }

    private var requestReviewJSON: String {
        #"{"pluginId":"tmdb","externalIdentity":{"namespace":"tmdb","value":"603"},"entityKind":"movie","kind":"movie","proposal":\#(proposalJSON),"revision":"revision-1","targets":[{"proposalId":"movie-603","kind":"movie","entityKind":"movie","externalIdentity":{"namespace":"tmdb","value":"603"},"requestable":true,"position":null,"year":1999,"monitored":null}]}"#
    }

    private func identifyQueueItemJSON(entityID: UUID, state: String) -> String {
        #"{"id":"12121212-1212-1212-1212-121212121212","entityId":"\#(entityID)","entityKind":"movie","title":"Matrix","isNsfw":false,"state":"\#(state)","provider":"tmdb","action":"search","query":{"title":"Matrix","url":null,"externalIds":null,"requireChoice":true,"fields":null,"limit":25},"candidates":[],"proposal":\#(state == "queued" ? "null" : proposalJSON),"error":null,"cascadeRunning":false,"createdAt":"2026-07-12T12:00:00Z","updatedAt":"2026-07-12T12:00:00Z","completedAt":null}"#
    }
}
