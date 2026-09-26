import XCTest

@testable import PrismediaCore

final class RequestFeatureAPIClientTests: XCTestCase {
    func testRequestLibraryTargetsUseAccessibleSummaryEndpoint() async throws {
        let rootID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let loader = MockHTTPDataLoader(responses: [
            .json(
                #"[{"id":"\#(rootID)","label":"Movies","scanVideos":true,"scanImages":false,"scanAudio":false,"scanBooks":false,"isNsfw":false}]"#
            )
        ])
        let client = PrismediaAPIClient(
            serverURL: URL(string: "https://media.example.test")!,
            accessToken: "token",
            loader: loader
        )

        let roots = try await client.listRequestLibraryRoots()

        XCTAssertEqual(roots.map(\.id), [rootID])
        XCTAssertEqual(roots.map(\.label), ["Movies"])
        XCTAssertEqual(loader.requests.map(\.url?.path), ["/api/libraries/accessible"])
    }

    func testReviewedBookRequestSendsRenditionCodesAndDecodesEveryOutcome() async throws {
        let bookID = UUID(uuidString: "66666666-6666-6666-6666-666666666666")!
        let rootID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let profileID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let item = #"{"externalId":"openlibrary:OL1W","title":"Example","outcome":"requested","entityId":"\#(bookID)","acquisitionId":null}"#
        let loader = MockHTTPDataLoader(responses: [
            .json(
                """
                {"containerEntityId": null, "items": [\(item)],
                 "bookRenditions": [
                   {"rendition": "ebook", "item": \(item), "error": null},
                   {"rendition": "braille", "item": null, "error": "Not offered."}
                 ]}
                """
            )
        ])
        let client = PrismediaAPIClient(
            serverURL: URL(string: "https://media.example.test")!,
            accessToken: "token",
            loader: loader
        )

        let response = try await client.commitAdministrativeReviewedRequest(
            AdministrativeReviewedRequestCommitRequest(
                kind: RequestKindDefinition.book.rawValue,
                pluginID: "openlibrary",
                rootExternalIdentity: AdministrativeExternalIdentity(namespace: "openlibrary", value: "OL1W"),
                proposalRevision: "revision-1",
                selectedProposalIDs: ["root"],
                bookRenditions: [
                    AdministrativeBookRenditionRequestChoice(
                        rendition: .ebook, targetLibraryRootID: rootID, profileID: profileID
                    ),
                    AdministrativeBookRenditionRequestChoice(
                        rendition: .audiobook, targetLibraryRootID: nil, profileID: nil
                    ),
                ]
            )
        )

        XCTAssertEqual(
            response.bookRenditions?.map(\.rendition),
            [.ebook, EntityBookRendition(rawValue: "braille")],
            "A future format decodes with its own code instead of failing or reading as a known one."
        )
        XCTAssertEqual(
            response.bookRenditions?.first?.item?.outcome,
            PrismediaContractCodes.RequestCommitOutcome.requested
        )
        XCTAssertEqual(response.bookRenditions?.last?.error, "Not offered.")

        let request = try XCTUnwrap(loader.requests.first)
        XCTAssertEqual(request.url?.path, "/api/requests/commit-reviewed")
        let body = try XCTUnwrap(JSONSerialization.jsonObject(with: try XCTUnwrap(request.httpBody)) as? [String: Any])
        let sent = try XCTUnwrap(body["bookRenditions"] as? [[String: Any]])
        XCTAssertEqual(sent.map { $0["rendition"] as? String }, ["ebook", "audiobook"])
        XCTAssertEqual(sent.first?["targetLibraryRootId"] as? String, rootID.uuidString)
        XCTAssertEqual(sent.first?["profileId"] as? String, profileID.uuidString)
    }
}
