import XCTest

@testable import PrismediaCore

final class PrismediaAPIClientTests: XCTestCase {
    private let serverURL = URL(string: "https://media.example.test")!

    private let loginResponseJSON = """
        {
          "accessToken": "opaque-session-token",
          "user": {
            "id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
            "username": "paul",
            "displayName": "Paul",
            "role": "admin",
            "allowSfw": true,
            "allowNsfw": true,
            "canCreateLibraries": true,
            "enabled": true,
            "lastLoginAt": "2026-07-07T18:30:00.1234567+00:00",
            "createdAt": "2026-07-06T20:00:00Z",
            "updatedAt": "2026-07-07T18:30:00.1234567Z"
          }
        }
        """

    func testLoginPostsCredentialsAndDecodesSession() async throws {
        let loader = MockHTTPDataLoader(responses: [.json(loginResponseJSON)])
        let client = PrismediaAPIClient(serverURL: serverURL, loader: loader)

        let response = try await client.login(
            username: "paul",
            password: "hunter22",
            device: ClientDeviceInfo(client: "Prismedia iOS", deviceName: "Test iPhone", deviceID: "device-1")
        )

        XCTAssertEqual(response.accessToken, "opaque-session-token")
        XCTAssertEqual(response.user.username, "paul")
        XCTAssertEqual(response.user.role, .admin)
        XCTAssertTrue(response.user.isAdmin)
        XCTAssertNotNil(response.user.lastLoginAt, "fractional-second .NET timestamps must decode")

        let request = try XCTUnwrap(loader.requests.first)
        XCTAssertEqual(request.url?.absoluteString, "https://media.example.test/api/auth/login")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))

        let body = try JSONSerialization.jsonObject(with: XCTUnwrap(request.httpBody)) as? [String: Any]
        XCTAssertEqual(body?["username"] as? String, "paul")
        XCTAssertEqual(body?["password"] as? String, "hunter22")
        XCTAssertEqual(body?["client"] as? String, "Prismedia iOS")
        XCTAssertEqual(body?["deviceName"] as? String, "Test iPhone")
        XCTAssertEqual(body?["deviceId"] as? String, "device-1")
    }

    func testAuthenticatedRequestsSendBearerToken() async throws {
        let loader = MockHTTPDataLoader(responses: [.json(loginResponseJSON)])
        let client = PrismediaAPIClient(serverURL: serverURL, loader: loader)
            .authenticated(with: "opaque-session-token")

        _ = try? await client.currentUser()

        let request = try XCTUnwrap(loader.requests.first)
        XCTAssertEqual(request.url?.absoluteString, "https://media.example.test/api/auth/me")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer opaque-session-token")
    }

    func testListEntitiesBuildsWebParityQuery() async throws {
        let loader = MockHTTPDataLoader(responses: [
            .json(
                """
                { "items": [], "nextCursor": null, "totalCount": "0" }
                """)
        ])
        let client = PrismediaAPIClient(serverURL: serverURL, loader: loader)
            .authenticated(with: "token")

        let query = EntityListQuery(
            kind: .book,
            sort: "added",
            seed: 42,
            favorite: true,
            organized: false,
            ratingMin: 2,
            ratingMax: 4,
            unrated: false,
            status: "in-progress",
            bookType: "comic,manga",
            bookFormat: "image-archive",
            nsfw: true,
            hasFile: false,
            played: true,
            orphaned: false,
            wanted: true,
            acquisitionStatus: AcquisitionStatus(rawValue: "downloading"),
            cursor: "next/page+2"
        )
        let response = try await client.listEntities(query, limit: 48, search: "ronin")

        XCTAssertEqual(response.totalCount, 0, "string-typed totalCount must decode")

        let url = try XCTUnwrap(loader.requests.first?.url)
        let request = try XCTUnwrap(loader.requests.first)
        XCTAssertEqual(request.cachePolicy, .reloadIgnoringLocalCacheData)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Cache-Control"), "no-cache")
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        XCTAssertEqual(components.path, "/api/entities")

        let items = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value) })
        XCTAssertEqual(items["kind"], "book")
        XCTAssertEqual(items["sort"], "added")
        XCTAssertEqual(items["sortDir"], "desc")
        XCTAssertEqual(items["seed"], "42")
        XCTAssertEqual(items["favorite"], "true")
        XCTAssertEqual(items["organized"], "false")
        XCTAssertEqual(items["ratingMin"], "2")
        XCTAssertEqual(items["ratingMax"], "4")
        XCTAssertEqual(items["unrated"], "false")
        XCTAssertEqual(items["status"], "in-progress")
        XCTAssertEqual(items["bookType"], "comic,manga")
        XCTAssertEqual(items["bookFormat"], "image-archive")
        XCTAssertEqual(items["hasFile"], "false")
        XCTAssertEqual(items["played"], "true")
        XCTAssertEqual(items["orphaned"], "false")
        XCTAssertEqual(items["wanted"], "true")
        XCTAssertEqual(items["acquisitionStatus"], "downloading")
        XCTAssertEqual(items["query"], "ronin")
        XCTAssertEqual(items["cursor"], "next/page+2")
        XCTAssertEqual(items["limit"], "48")
        XCTAssertEqual(items["hideNsfw"], "true")
        XCTAssertEqual(items["nsfw"], "false")
    }

    func testListAllEntitiesFollowsEachCursorAndReturnsTheCompleteLibrary() async throws {
        let firstID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let secondID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let loader = MockHTTPDataLoader(responses: [
            .json(
                #"{"items":[{"id":"\#(firstID)","kind":"audio-track","title":"First"}],"nextCursor":"page-2","totalCount":2}"#
            ),
            .json(
                #"{"items":[{"id":"\#(secondID)","kind":"audio-track","title":"Second"}],"nextCursor":null,"totalCount":2}"#
            ),
        ])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "token", loader: loader)

        let tracks = try await client.listAllEntities(EntityListQuery(kind: .audioTrack), pageSize: 250)

        XCTAssertEqual(tracks.map(\.id), [firstID, secondID])
        XCTAssertEqual(loader.requests.count, 2)
        XCTAssertNil(queryItem("cursor", in: loader.requests[0]))
        XCTAssertEqual(queryItem("cursor", in: loader.requests[1]), "page-2")
        XCTAssertTrue(loader.requests.allSatisfy { queryItem("limit", in: $0) == "250" })
    }

    func testListAllEntitiesStopsWhenTheServerRepeatsACursor() async throws {
        let trackID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let loader = MockHTTPDataLoader(responses: [
            .json(
                #"{"items":[{"id":"\#(trackID)","kind":"audio-track","title":"First"}],"nextCursor":"stuck","totalCount":1}"#
            ),
            .json(
                #"{"items":[{"id":"\#(trackID)","kind":"audio-track","title":"First"}],"nextCursor":"stuck","totalCount":1}"#
            ),
        ])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "token", loader: loader)

        let tracks = try await client.listAllEntities(EntityListQuery(kind: .audioTrack))

        XCTAssertEqual(tracks.map(\.id), [trackID])
        XCTAssertEqual(loader.requests.count, 2)
    }

    func testListQueryOnlyUsesExplicitNsfwFilterWhenPrivacyAllowsIt() {
        let query = EntityListQuery(nsfw: true, hideNsfw: false)
        let items = Dictionary(
            uniqueKeysWithValues: query.queryItems(limit: 10, search: nil).map { ($0.name, $0.value) }
        )

        XCTAssertEqual(items["hideNsfw"], "false")
        XCTAssertEqual(items["nsfw"], "true")
    }

    func testFetchEntityUsesSharedDetailEndpointAndVisibilityQuery() async throws {
        let entityID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let loader = MockHTTPDataLoader(responses: [
            .json(
                """
                {
                  "id": "\(entityID.uuidString)",
                  "kind": "audio-track",
                  "title": "Native Track",
                  "parentEntityId": null,
                  "sortOrder": null,
                  "capabilities": [],
                  "childrenByKind": [],
                  "relationships": []
                }
                """)
        ])
        let client = PrismediaAPIClient(serverURL: serverURL, loader: loader)
            .allowingNsfwContent(true)
            .authenticated(with: "token")

        let detail = try await client.fetchEntity(id: entityID)

        XCTAssertEqual(detail.id, entityID)
        XCTAssertEqual(detail.kind, .audioTrack)
        let request = try XCTUnwrap(loader.requests.first)
        XCTAssertEqual(request.url?.path, "/api/entities/\(entityID.uuidString.lowercased())")
        XCTAssertEqual(
            URLComponents(url: try XCTUnwrap(request.url), resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "hideNsfw" })?.value,
            "false"
        )
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer token")
    }

    func testFetchBookUsesKindSpecificDetailEndpoint() async throws {
        let entityID = UUID(uuidString: "29bfc229-2c44-4db4-ae9d-7842c6735d2c")!
        let loader = MockHTTPDataLoader(responses: [
            .json(
                """
                {
                  "id": "\(entityID.uuidString)",
                  "kind": "book",
                  "title": "A Game of Thrones",
                  "bookType": "novel",
                  "format": "epub",
                  "hasSourceMedia": true,
                  "capabilities": [],
                  "childrenByKind": [],
                  "relationships": []
                }
                """)
        ])
        let client = PrismediaAPIClient(serverURL: serverURL, loader: loader)
            .allowingNsfwContent(true)
            .authenticated(with: "token")

        let detail = try await client.fetchEntity(id: entityID, kind: .book)

        XCTAssertEqual(detail.bookType, "novel")
        XCTAssertEqual(detail.bookFormat, .epub)
        let request = try XCTUnwrap(loader.requests.first)
        XCTAssertEqual(request.url?.path, "/api/books/\(entityID.uuidString.lowercased())")
        XCTAssertEqual(queryItem("hideNsfw", in: request), "false")
    }

    func testUpdateEntityRatingPatchesTheSharedRatingEndpoint() async throws {
        let entityID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let loader = MockHTTPDataLoader(responses: [.json(entityDetailJSON(id: entityID, rating: 4))])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "token", loader: loader)

        let detail = try await client.updateEntityRating(id: entityID, value: 4)

        XCTAssertEqual(detail.id, entityID)
        let request = try XCTUnwrap(loader.requests.first)
        XCTAssertEqual(request.url?.path, "/api/entities/\(entityID.uuidString.lowercased())/rating")
        XCTAssertEqual(request.httpMethod, "PATCH")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer token")
        let body = try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(request.httpBody)) as? [String: Any])
        XCTAssertEqual(body["value"] as? Int, 4)
    }

    func testUpdateEntityFlagsSendsExplicitNullableFlagFields() async throws {
        let entityID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let loader = MockHTTPDataLoader(responses: [.json(entityDetailJSON(id: entityID, rating: nil))])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "token", loader: loader)

        _ = try await client.updateEntityFlags(
            id: entityID,
            isFavorite: true,
            isNsfw: nil,
            isOrganized: nil
        )

        let request = try XCTUnwrap(loader.requests.first)
        XCTAssertEqual(request.url?.path, "/api/entities/\(entityID.uuidString.lowercased())/flags")
        XCTAssertEqual(request.httpMethod, "PATCH")
        let body = try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(request.httpBody)) as? [String: Any])
        XCTAssertEqual(body["isFavorite"] as? Bool, true)
        XCTAssertTrue(body["isNsfw"] is NSNull)
        XCTAssertTrue(body["isOrganized"] is NSNull)
    }

    func testUpdateReadingProgressPatchesTheOwningBookWithExactPWAContract() async throws {
        let bookID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let chapterID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let loader = MockHTTPDataLoader(responses: [.json(entityDetailJSON(id: bookID, rating: nil))])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "token", loader: loader)

        _ = try await client.updateEntityProgress(
            id: bookID,
            request: EntityProgressUpdateRequest(
                currentEntityID: chapterID,
                unit: .page,
                index: 4,
                total: 20,
                mode: .webtoon,
                completed: nil,
                reset: false,
                location: nil
            )
        )

        let request = try XCTUnwrap(loader.requests.first)
        XCTAssertEqual(request.url?.path, "/api/entities/\(bookID.uuidString.lowercased())/progress")
        XCTAssertEqual(request.httpMethod, "PATCH")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer token")
        let body = try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(request.httpBody)) as? [String: Any])
        XCTAssertEqual(body["currentEntityId"] as? String, chapterID.uuidString)
        XCTAssertEqual(body["unit"] as? String, "page")
        XCTAssertEqual(body["index"] as? Int, 4)
        XCTAssertEqual(body["total"] as? Int, 20)
        XCTAssertEqual(body["mode"] as? String, "webtoon")
        XCTAssertTrue(body["completed"] is NSNull)
        XCTAssertEqual(body["reset"] as? Bool, false)
        XCTAssertTrue(body["location"] is NSNull)
    }

    func testVideoPlaybackReportsUseRootJellyfinSessionEndpointsAndExactIdentifiers() async throws {
        let videoID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let loader = MockHTTPDataLoader(responses: [
            .json("", statusCode: 204),
            .json("", statusCode: 204),
            .json("", statusCode: 204),
        ])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "token", loader: loader)
        let report = VideoPlaybackReport(
            videoID: videoID,
            mediaSourceID: "media-source",
            playSessionID: "play-session",
            positionSeconds: 12.345,
            isPaused: false,
            isMuted: false
        )

        try await client.reportVideoPlayback(.started, report: report)
        try await client.reportVideoPlayback(.progress, report: report)
        try await client.reportVideoPlayback(.stopped, report: report)

        XCTAssertEqual(
            loader.requests.compactMap(\.url?.path),
            ["/Sessions/Playing", "/Sessions/Playing/Progress", "/Sessions/Playing/Stopped"]
        )
        for request in loader.requests {
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer token")
            let body = try XCTUnwrap(
                JSONSerialization.jsonObject(with: XCTUnwrap(request.httpBody)) as? [String: Any]
            )
            XCTAssertEqual(body["ItemId"] as? String, videoID.uuidString)
            XCTAssertEqual(body["MediaSourceId"] as? String, "media-source")
            XCTAssertEqual(body["PlaySessionId"] as? String, "play-session")
            XCTAssertEqual(body["PositionTicks"] as? Int, 123_450_000)
            XCTAssertEqual(body["IsPaused"] as? Bool, false)
            XCTAssertEqual(body["IsMuted"] as? Bool, false)
        }
    }

    func testMarkVideoPlayedUsesRootJellyfinPlayedItemEndpoint() async throws {
        let videoID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let loader = MockHTTPDataLoader(responses: [.json(#"{"Played":true}"#)])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "token", loader: loader)

        try await client.markVideoPlayed(videoID: videoID)

        let request = try XCTUnwrap(loader.requests.first)
        XCTAssertEqual(request.url?.path, "/UserPlayedItems/\(videoID.uuidString.lowercased())")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer token")
    }

    func testEntityPageSourceUsesAuthenticatedFileEndpoint() async throws {
        let pageID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        let bytes = Data([0x89, 0x50, 0x4e, 0x47])
        let loader = MockHTTPDataLoader(responses: [.data(bytes)])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "token", loader: loader)

        let result = try await client.entitySourceData(id: pageID)

        XCTAssertEqual(result, bytes)
        let request = try XCTUnwrap(loader.requests.first)
        XCTAssertEqual(request.url?.path, "/api/entities/\(pageID.uuidString.lowercased())/files/source")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer token")
    }

    func testFetchEntityThumbnailsBatchesParentArtistResolution() async throws {
        let artistID = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
        let loader = MockHTTPDataLoader(responses: [
            .json(
                """
                {"items":[{"id":"\(artistID)","kind":"music-artist","title":"Imagine Dragons"}]}
                """)
        ])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "token", loader: loader)

        let artists = try await client.fetchEntityThumbnails(ids: [artistID])

        XCTAssertEqual(artists.map(\.title), ["Imagine Dragons"])
        let request = try XCTUnwrap(loader.requests.first)
        XCTAssertEqual(request.url?.path, "/api/entities/thumbnails")
        XCTAssertEqual(request.httpMethod, "POST")
        let body = try JSONSerialization.jsonObject(with: XCTUnwrap(request.httpBody)) as? [String: Any]
        XCTAssertEqual(body?["ids"] as? [String], [artistID.uuidString])
    }

    func testListsCollectionsAndAddsEntityUsingExistingCollectionItemsEndpoint() async throws {
        let collectionID = UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!
        let albumID = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
        let loader = MockHTTPDataLoader(responses: [
            .json(#"{"items":[{"id":"\#(collectionID)","kind":"collection","title":"Road Trip"}],"totalCount":1}"#),
            .json(#"{"count":1}"#),
        ])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "token", loader: loader)

        let collections = try await client.listCollections()
        let count = try await client.addToCollection(
            collectionID: collectionID,
            items: [CollectionEntityReference(entityType: .audioLibrary, entityID: albumID)]
        )

        XCTAssertEqual(collections.items.map(\.title), ["Road Trip"])
        XCTAssertEqual(count, 1)
        XCTAssertEqual(loader.requests[0].url?.path, "/api/collections")
        XCTAssertEqual(loader.requests[1].url?.path, "/api/collections/\(collectionID.uuidString.lowercased())/items")
        XCTAssertEqual(loader.requests[1].httpMethod, "POST")
        let body = try JSONSerialization.jsonObject(with: XCTUnwrap(loader.requests[1].httpBody)) as? [String: Any]
        let items = body?["items"] as? [[String: Any]]
        XCTAssertEqual(items?.first?["entityType"] as? String, "audio-library")
        XCTAssertEqual(items?.first?["entityId"] as? String, albumID.uuidString)
    }

    func testFetchCollectionItemsDecodesMixedEntitiesInServerOrderAndAppliesVisibility() async throws {
        let collectionID = UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!
        let movieID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let seriesID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let bookID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        let trackID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
        let galleryID = UUID(uuidString: "55555555-5555-5555-5555-555555555555")!
        let loader = MockHTTPDataLoader(responses: [
            .json(
                """
                {
                  "items": [
                    {
                      "id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
                      "collectionId": "\(collectionID.uuidString)",
                      "entityType": "movie",
                      "entityId": "\(movieID.uuidString)",
                      "source": "manual",
                      "sortOrder": 50,
                      "addedAt": "2026-07-11T12:00:00Z",
                      "entity": { "id": "\(movieID.uuidString)", "kind": "movie", "title": "First" }
                    },
                    {
                      "id": "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
                      "collectionId": "\(collectionID.uuidString)",
                      "entityType": "video-series",
                      "entityId": "\(seriesID.uuidString)",
                      "source": "dynamic",
                      "sortOrder": 1,
                      "addedAt": "2026-07-10T12:00:00Z",
                      "entity": { "id": "\(seriesID.uuidString)", "kind": "video-series", "title": "Second" }
                    },
                    {
                      "entity": { "id": "\(bookID.uuidString)", "kind": "book", "title": "Third" }
                    },
                    {
                      "entity": { "id": "\(trackID.uuidString)", "kind": "audio-track", "title": "Fourth" }
                    },
                    {
                      "entity": { "id": "\(galleryID.uuidString)", "kind": "gallery", "title": "Fifth" }
                    }
                  ]
                }
                """)
        ])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "token", loader: loader)

        let items = try await client.fetchCollectionItems(collectionID: collectionID)

        XCTAssertEqual(items.map(\.id), [movieID, seriesID, bookID, trackID, galleryID])
        XCTAssertEqual(items.map(\.kind), [.movie, .videoSeries, .book, .audioTrack, .gallery])
        XCTAssertEqual(items.map(\.title), ["First", "Second", "Third", "Fourth", "Fifth"])
        let request = try XCTUnwrap(loader.requests.first)
        XCTAssertEqual(
            request.url?.path,
            "/api/collections/\(collectionID.uuidString.lowercased())/items"
        )
        XCTAssertEqual(queryItem("hideNsfw", in: request), "true")
        XCTAssertEqual(request.httpMethod, "GET")
    }

    func testListEntitiesCanExplicitlyIncludeNsfwContent() async throws {
        let loader = MockHTTPDataLoader(responses: [
            .json(#"{"items":[],"nextCursor":null,"totalCount":0}"#)
        ])
        let client = PrismediaAPIClient(serverURL: serverURL, loader: loader)
            .allowingNsfwContent(true)
            .authenticated(with: "token")

        _ = try await client.listEntities(EntityListQuery())

        let url = try XCTUnwrap(loader.requests.first?.url)
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let items = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value) })
        XCTAssertEqual(items["hideNsfw"], "false")
        XCTAssertFalse(items.keys.contains("nsfw"), "Opting in must include both SFW and NSFW results.")
    }

    func testDefaultClientForcesSafeFilteringEvenWhenACallerRequestsNsfwContent() async throws {
        let loader = MockHTTPDataLoader(responses: [
            .json(#"{"items":[],"nextCursor":null,"totalCount":0}"#)
        ])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "token", loader: loader)

        _ = try await client.listEntities(EntityListQuery(nsfw: true, hideNsfw: false))

        let request = try XCTUnwrap(loader.requests.first)
        XCTAssertEqual(queryItem("hideNsfw", in: request), "true")
        XCTAssertEqual(queryItem("nsfw", in: request), "false")
    }

    func testAllowedNsfwPreferenceAppliesToEveryVisibilityAwareRequest() async throws {
        let entityID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let loader = MockHTTPDataLoader(responses: [
            .json(#"{"items":[],"nextCursor":null,"totalCount":0}"#),
            .json(entityDetailJSON(id: entityID, rating: nil)),
            .json(#"{"items":[]}"#),
            .json(#"{"items":[],"nextCursor":null,"totalCount":0}"#),
            .json(
                """
                {
                  "from": "2026-01-01T00:00:00Z",
                  "to": "2026-01-02T00:00:00Z",
                  "totalEvents": 0,
                  "completedCount": 0,
                  "skippedCount": 0,
                  "distinctEntityCount": 0,
                  "topEntities": [],
                  "recentEvents": [],
                  "dailyEvents": []
                }
                """),
        ])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "token", loader: loader)
            .allowingNsfwContent(true)

        _ = try await client.listEntities(EntityListQuery())
        _ = try await client.fetchEntity(id: entityID)
        _ = try await client.fetchEntityThumbnails(ids: [entityID])
        _ = try await client.listCollections()
        _ = try await client.fetchPlaybackStatistics(
            PlaybackStatisticsQuery(
                from: Date(timeIntervalSince1970: 1_767_225_600),
                to: Date(timeIntervalSince1970: 1_767_312_000)
            )
        )

        XCTAssertEqual(loader.requests.count, 5)
        XCTAssertTrue(loader.requests.allSatisfy { queryItem("hideNsfw", in: $0) == "false" })
        XCTAssertNil(queryItem("nsfw", in: loader.requests[0]))
    }

    func testAuthenticatedClientCopiesObserveLiveNsfwPreferenceChanges() {
        let configured = PrismediaAPIClient(serverURL: serverURL)
            .allowingNsfwContent(false)
        let authenticated = configured.authenticated(with: "token")

        configured.updateNsfwContentPreference(true)

        XCTAssertTrue(configured.allowsNsfwContent)
        XCTAssertTrue(authenticated.allowsNsfwContent)
    }

    func testInvalidCredentialsProducesActionableError() async {
        let loader = MockHTTPDataLoader(responses: [
            .json(
                """
                { "code": "invalid_credentials", "message": "Invalid username or password." }
                """, statusCode: 401)
        ])
        let client = PrismediaAPIClient(serverURL: serverURL, loader: loader)

        do {
            _ = try await client.login(username: "paul", password: "wrong")
            XCTFail("Expected login to reject invalid credentials.")
        } catch {
            XCTAssertEqual(error.localizedDescription, "Invalid username or password.")
            XCTAssertTrue((error as? PrismediaAPIError)?.isAuthenticationFailure == true)
        }
    }

    func testRateLimitProducesActionableError() async {
        let loader = MockHTTPDataLoader(responses: [
            .json(
                """
                { "code": "auth_rate_limited", "message": "Too many attempts." }
                """, statusCode: 429)
        ])
        let client = PrismediaAPIClient(serverURL: serverURL, loader: loader)

        do {
            _ = try await client.login(username: "paul", password: "pw")
            XCTFail("Expected login to surface rate limiting.")
        } catch {
            XCTAssertEqual(
                error.localizedDescription,
                "Too many sign-in attempts. Wait a couple of minutes and try again."
            )
        }
    }

    func testRedirectToSSOProducesProxyAuthError() async {
        let loader = MockHTTPDataLoader(responses: [
            .htmlRedirect("https://auth.example.test/?rd=https%3A%2F%2Fmedia.example.test%2Fapi%2Fauth%2Fme")
        ])
        let client = PrismediaAPIClient(serverURL: serverURL, loader: loader)
            .authenticated(with: "token")

        do {
            _ = try await client.currentUser()
            XCTFail("Expected proxy sign-in redirects to be rejected.")
        } catch {
            XCTAssertEqual(
                error.localizedDescription,
                "The Prismedia API was redirected to a sign-in page before the request reached the server. Bypass proxy SSO for /api/* or use a direct server URL."
            )
        }
    }

    func testAssetURLIsPublicAndTokenURLCarriesAPIKey() {
        let client = PrismediaAPIClient(serverURL: serverURL, loader: MockHTTPDataLoader(responses: []))
            .authenticated(with: "opaque-session-token")

        XCTAssertEqual(
            client.assetURL(for: "/assets/videos/1/thumb.jpg")?.absoluteString,
            "https://media.example.test/assets/videos/1/thumb.jpg"
        )

        XCTAssertEqual(
            client.tokenAuthenticatedURL(for: "/api/video-stream/1/hls2/master.m3u8")?.absoluteString,
            "https://media.example.test/api/video-stream/1/hls2/master.m3u8?api_key=opaque-session-token"
        )
    }

    func testCrossOriginMediaURLsNeverReceiveSessionCredentials() async throws {
        let loader = MockHTTPDataLoader(responses: [.data(Data())])
        let client = PrismediaAPIClient(serverURL: serverURL, loader: loader)
            .authenticated(with: "opaque-session-token")
        let externalURL = "https://cdn.example.test/trickplay/index.vtt?variant=small"

        XCTAssertEqual(client.tokenAuthenticatedURL(for: externalURL)?.absoluteString, externalURL)
        XCTAssertEqual(client.authenticatedMediaURL(for: externalURL)?.absoluteString, externalURL)

        _ = try await client.mediaData(for: externalURL)
        let request = try XCTUnwrap(loader.requests.first)
        XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
        XCTAssertNil(
            URLComponents(url: try XCTUnwrap(request.url), resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "api_key" })
        )
    }

    func testAudioStreamURLUsesTheNativeEndpointAndSessionToken() throws {
        let trackID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let client = PrismediaAPIClient(serverURL: serverURL, loader: MockHTTPDataLoader(responses: []))
            .authenticated(with: "opaque-session-token")

        let url = try XCTUnwrap(client.audioStreamURL(for: trackID))

        XCTAssertEqual(url.path, "/api/audio-stream/\(trackID.uuidString.lowercased())")
        XCTAssertEqual(
            URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "api_key" })?.value,
            "opaque-session-token"
        )
    }

    func testVideoPlaybackNegotiationAdvertisesAppleNativeCapabilities() async throws {
        let videoID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let loader = MockHTTPDataLoader(responses: [
            .json(
                """
                {
                  "PlaySessionId":"session-1",
                  "MediaSources":[{
                    "Id":"source-1","Path":"/media/movie.mkv","Protocol":"File","Container":"mkv",
                    "SupportsDirectPlay":false,"SupportsDirectStream":true,"SupportsTranscoding":true,
                    "TranscodingUrl":"/Videos/\(videoID)/hls/remux/stream.m3u8?PlaySessionId=session-1",
                    "MediaStreams":[],
                    "TranscodingInfo":{"Container":"mp4","VideoCodec":"hevc","AudioCodec":"aac","Protocol":"hls","IsVideoDirect":true,"IsAudioDirect":false}
                  }]
                }
                """)
        ])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "token", loader: loader)

        let plan = try await client.negotiateVideoPlayback(videoID: videoID)

        XCTAssertEqual(plan.delivery, .remux)
        XCTAssertEqual(plan.url.path, "/Videos/\(videoID)/hls/remux/stream.m3u8")
        XCTAssertEqual(plan.httpHeaders["Authorization"], "Bearer token")
        let request = try XCTUnwrap(loader.requests.first)
        XCTAssertEqual(request.url?.path, "/Items/\(videoID.uuidString.lowercased())/PlaybackInfo")
        XCTAssertEqual(request.httpMethod, "POST")
        let body = try XCTUnwrap(
            JSONSerialization.jsonObject(with: XCTUnwrap(request.httpBody)) as? [String: Any]
        )
        XCTAssertEqual(body["EnableDirectPlay"] as? Bool, true)
        XCTAssertEqual(body["EnableDirectStream"] as? Bool, true)
        XCTAssertEqual(body["EnableTranscoding"] as? Bool, true)
        let profile = try XCTUnwrap(body["DeviceProfile"] as? [String: Any])
        let directProfiles = try XCTUnwrap(profile["DirectPlayProfiles"] as? [[String: Any]])
        XCTAssertTrue(directProfiles.contains { ($0["Container"] as? String)?.contains("mp4") == true })
        XCTAssertTrue(directProfiles.contains { ($0["VideoCodec"] as? String)?.contains("h264") == true })
    }

    func testCrossOriginTranscodePlanDoesNotForwardSessionCredentials() async throws {
        let videoID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let loader = MockHTTPDataLoader(responses: [
            .json(
                """
                {
                  "PlaySessionId":"session-1",
                  "MediaSources":[{
                    "Id":"source-1","SupportsDirectPlay":false,"SupportsTranscoding":true,
                    "TranscodingUrl":"https://cdn.example.test/hls/stream.m3u8",
                    "MediaStreams":[],
                    "TranscodingInfo":{"Protocol":"hls","IsVideoDirect":false,"IsAudioDirect":false}
                  }]
                }
                """)
        ])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "token", loader: loader)

        let plan = try await client.negotiateVideoPlayback(videoID: videoID)

        XCTAssertEqual(plan.url.absoluteString, "https://cdn.example.test/hls/stream.m3u8")
        XCTAssertTrue(plan.httpHeaders.isEmpty)
    }

    func testForcedVideoFallbackDisablesDirectAndDirectStream() async throws {
        let videoID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let loader = MockHTTPDataLoader(responses: [
            .json(
                """
                {
                  "PlaySessionId":"session-1",
                  "MediaSources":[{
                    "Id":"source-1","Path":"/media/movie.mkv","Protocol":"File","Container":"mkv",
                    "SupportsDirectPlay":false,"SupportsDirectStream":false,"SupportsTranscoding":true,
                    "TranscodingUrl":"/Videos/\(videoID)/master.m3u8?PlaySessionId=session-1",
                    "MediaStreams":[],
                    "TranscodingInfo":{"Container":"ts","VideoCodec":"h264","AudioCodec":"aac","Protocol":"hls","IsVideoDirect":false,"IsAudioDirect":false}
                  }]
                }
                """)
        ])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "token", loader: loader)

        let plan = try await client.negotiateVideoPlayback(videoID: videoID, forceTranscode: true)

        XCTAssertEqual(plan.delivery, .transcode)
        let body = try XCTUnwrap(
            JSONSerialization.jsonObject(with: XCTUnwrap(loader.requests[0].httpBody)) as? [String: Any]
        )
        XCTAssertEqual(body["EnableDirectPlay"] as? Bool, false)
        XCTAssertEqual(body["EnableDirectStream"] as? Bool, false)
    }

    func testDirectVideoPlanUsesAuthenticatedRangeStream() async throws {
        let videoID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let loader = MockHTTPDataLoader(responses: [
            .json(
                """
                {
                  "PlaySessionId":"session-1",
                  "MediaSources":[{
                    "Id":"source-1","Path":"/media/movie.mp4","Protocol":"File","Container":"mp4",
                    "RunTimeTicks":900000000,"SupportsDirectPlay":true,"SupportsDirectStream":true,
                    "SupportsTranscoding":true,"TranscodingUrl":null,"MediaStreams":[],"TranscodingInfo":null
                  }]
                }
                """)
        ])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "opaque-token", loader: loader)

        let plan = try await client.negotiateVideoPlayback(videoID: videoID)

        XCTAssertEqual(plan.delivery, .direct)
        XCTAssertEqual(plan.durationSeconds, 90)
        XCTAssertEqual(plan.url.path, "/Videos/\(videoID.uuidString.lowercased())/stream")
        XCTAssertEqual(queryItem("MediaSourceId", in: URLRequest(url: plan.url)), "source-1")
        XCTAssertEqual(queryItem("api_key", in: URLRequest(url: plan.url)), "opaque-token")
    }

    func testSelectingAudioStreamIsSentToNegotiationAndDirectStreamURL() async throws {
        let videoID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let loader = MockHTTPDataLoader(responses: [
            .json(
                """
                {
                  "PlaySessionId":"session-1",
                  "MediaSources":[{
                    "Id":"source-1","RunTimeTicks":900000000,"SupportsDirectPlay":false,
                    "SupportsTranscoding":true,
                    "TranscodingUrl":"/Videos/11111111-1111-1111-1111-111111111111/hls/remux/stream.m3u8?AudioStreamIndex=3",
                    "MediaStreams":[],
                    "TranscodingInfo":{"IsVideoDirect":true,"VideoCodec":"hevc","AudioCodec":"aac"}
                  }]
                }
                """)
        ])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "token", loader: loader)

        let plan = try await client.negotiateVideoPlayback(
            videoID: videoID,
            forceTranscode: false,
            audioStreamIndex: 3
        )

        let body =
            try JSONSerialization.jsonObject(
                with: XCTUnwrap(loader.requests.first?.httpBody)
            ) as? [String: Any]
        XCTAssertEqual(body?["AudioStreamIndex"] as? Int, 3)
        XCTAssertEqual(body?["EnableDirectPlay"] as? Bool, false)
        XCTAssertEqual(body?["EnableDirectStream"] as? Bool, true)
        XCTAssertEqual(plan.delivery, .remux)
        XCTAssertEqual(queryItem("AudioStreamIndex", in: URLRequest(url: plan.url)), "3")
    }

    func testRecordAudioTrackPlayPostsToCompletionEndpoint() async throws {
        let trackID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let loader = MockHTTPDataLoader(responses: [
            .json(
                """
                {
                  "id": "\(trackID.uuidString)",
                  "kind": "audio-track",
                  "title": "Played Track",
                  "parentEntityId": null,
                  "sortOrder": 1,
                  "hasSourceMedia": true,
                  "capabilities": [],
                  "childrenByKind": [],
                  "relationships": []
                }
                """)
        ])
        let client = PrismediaAPIClient(serverURL: serverURL, loader: loader)
            .authenticated(with: "token")

        try await client.recordAudioTrackPlay(id: trackID)

        let request = try XCTUnwrap(loader.requests.first)
        XCTAssertEqual(request.url?.path, "/api/audio-tracks/\(trackID.uuidString.lowercased())/play")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer token")
    }

    func testUpdateAudiobookProgressPatchesTheOwningBook() async throws {
        let bookID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let loader = MockHTTPDataLoader(responses: [.json(entityDetailJSON(id: bookID, rating: nil))])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "token", loader: loader)

        try await client.updateEntityPlayback(id: bookID, resumeSeconds: 3_725, completed: false)

        let request = try XCTUnwrap(loader.requests.first)
        XCTAssertEqual(request.url?.path, "/api/entities/\(bookID.uuidString.lowercased())/playback")
        XCTAssertEqual(request.httpMethod, "PATCH")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer token")
        let body = try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(request.httpBody)) as? [String: Any])
        XCTAssertEqual(body["resumeSeconds"] as? Double, 3_725)
        XCTAssertEqual(body["completed"] as? Bool, false)
    }

    func testLogoutPostsToAuthLogout() async throws {
        let loader = MockHTTPDataLoader(responses: [.json("", statusCode: 204)])
        let client = PrismediaAPIClient(serverURL: serverURL, loader: loader)
            .authenticated(with: "token")

        try await client.logout()

        let request = try XCTUnwrap(loader.requests.first)
        XCTAssertEqual(request.url?.absoluteString, "https://media.example.test/api/auth/logout")
        XCTAssertEqual(request.httpMethod, "POST")
    }

    func testFetchPlaybackStatisticsUsesTypedFiltersAndDecodesHistory() async throws {
        let loader = MockHTTPDataLoader(responses: [
            .json(
                """
                {
                  "from": "2026-01-01T00:00:00Z",
                  "to": "2026-07-01T00:00:00Z",
                  "totalEvents": 3,
                  "completedCount": 2,
                  "skippedCount": 1,
                  "distinctEntityCount": 1,
                  "topEntities": [{
                    "id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
                    "kind": "audio-track",
                    "title": "Signals",
                    "coverUrl": null,
                    "completedCount": 2,
                    "skippedCount": 1,
                    "lastEventAt": "2026-06-30T12:00:00Z"
                  }],
                  "recentEvents": [{
                    "id": "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
                    "entityId": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
                    "entityKind": "audio-track",
                    "entityTitle": "Signals",
                    "coverUrl": null,
                    "kind": "completed",
                    "occurredAt": "2026-06-30T12:00:00Z",
                    "positionSeconds": 180.5,
                    "durationSeconds": 181
                  }],
                  "dailyEvents": [{"date":"2026-06-30","completedCount":2,"skippedCount":1}]
                }
                """)
        ])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "token", loader: loader)
        let from = Date(timeIntervalSince1970: 1_767_225_600)
        let to = Date(timeIntervalSince1970: 1_782_864_000)

        let response = try await client.fetchPlaybackStatistics(
            PlaybackStatisticsQuery(
                from: from,
                to: to,
                kind: .audioTrack,
                eventKind: .completed
            )
        )

        XCTAssertEqual(response.totalEvents, 3)
        XCTAssertEqual(response.dailyEvents.first?.totalCount, 3)
        XCTAssertEqual(response.recentEvents.first?.positionSeconds, 180.5)
        let request = try XCTUnwrap(loader.requests.first)
        XCTAssertEqual(request.url?.path, "/api/playback/statistics")
        XCTAssertEqual(queryItem("kind", in: request), "audio-track")
        XCTAssertEqual(queryItem("eventKind", in: request), "completed")
        XCTAssertEqual(queryItem("hideNsfw", in: request), "true")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer token")
    }

    private func queryItem(_ name: String, in request: URLRequest) -> String? {
        guard let url = request.url else { return nil }
        return URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first { $0.name == name }?
            .value
    }

    private func entityDetailJSON(id: UUID, rating: Int?) -> String {
        let ratingCapability = rating.map { #", { "kind": "rating", "value": \#($0) }"# } ?? ""
        return """
            {
              "id": "\(id.uuidString)",
              "kind": "movie",
              "title": "Updated Movie",
              "hasSourceMedia": true,
              "capabilities": [
                { "kind": "flags", "isFavorite": true, "isNsfw": false, "isOrganized": false, "isWanted": false }
                \(ratingCapability)
              ],
              "childrenByKind": [],
              "relationships": []
            }
            """
    }
}

final class MockHTTPDataLoader: HTTPDataLoading, @unchecked Sendable {
    struct Response {
        let statusCode: Int
        let body: Data
        let headers: [String: String]

        static func json(_ value: String, statusCode: Int = 200) -> Response {
            Response(
                statusCode: statusCode,
                body: Data(value.utf8),
                headers: ["Content-Type": "application/json"]
            )
        }

        static func htmlRedirect(_ location: String) -> Response {
            Response(
                statusCode: 302,
                body: Data("<a>Found</a>".utf8),
                headers: [
                    "Content-Type": "text/html",
                    "Location": location,
                ]
            )
        }

        static func data(_ value: Data) -> Response {
            Response(statusCode: 200, body: value, headers: ["Content-Type": "application/octet-stream"])
        }
    }

    private var responses: [Response]
    private(set) var requests: [URLRequest] = []

    init(responses: [Response]) {
        self.responses = responses
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        let response =
            responses.isEmpty
            ? Response.json("{}", statusCode: 500)
            : responses.removeFirst()
        let url = try XCTUnwrap(request.url)
        let httpResponse = try XCTUnwrap(
            HTTPURLResponse(
                url: url,
                statusCode: response.statusCode,
                httpVersion: nil,
                headerFields: response.headers
            ))
        return (response.body, httpResponse)
    }
}
