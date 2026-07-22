import XCTest

@testable import PrismediaCore

final class EntityAcquisitionAPIClientTests: XCTestCase {
    private let serverURL = URL(string: "https://media.example.test")!
    private let entityID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    private let monitorID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    private let acquisitionID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!

    func testFetchMonitorStatePostsBoundedEntityIDRequest() async throws {
        let loader = MockHTTPDataLoader(responses: [.json(monitorStateJSON)])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "token", loader: loader)

        let state = try await client.fetchEntityMonitorState(entityID: entityID)

        XCTAssertEqual(state.entityID, entityID)
        XCTAssertEqual(state.trackableProviders, ["openlibrary"])
        XCTAssertEqual(state.monitor?.id, monitorID)
        XCTAssertEqual(state.latestAcquisition?.id, acquisitionID)
        let request = try XCTUnwrap(loader.requests.first)
        XCTAssertEqual(request.url?.path, "/api/monitors/states")
        XCTAssertEqual(request.httpMethod, "POST")
        let body = try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(request.httpBody)) as? [String: Any])
        XCTAssertEqual(body["entityIds"] as? [String], [entityID.uuidString])
    }

    func testFetchMonitorStatesPostsAllBoundedEntityIDs() async throws {
        let secondID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
        let secondState = monitorStateJSON.replacingOccurrences(
            of: entityID.uuidString,
            with: secondID.uuidString
        )
        let response = "[\(monitorStateJSON.dropFirst().dropLast()),\(secondState.dropFirst().dropLast())]"
        let loader = MockHTTPDataLoader(responses: [.json(response)])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "token", loader: loader)

        let states = try await client.fetchEntityMonitorStates(entityIDs: [entityID, secondID])

        XCTAssertEqual(states.map(\.entityID), [entityID, secondID])
        let request = try XCTUnwrap(loader.requests.first)
        let body = try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(request.httpBody)) as? [String: Any])
        XCTAssertEqual(body["entityIds"] as? [String], [entityID.uuidString, secondID.uuidString])
    }

    func testStartMonitorPostsEntityIDWithoutNarrowingPreset() async throws {
        let loader = MockHTTPDataLoader(responses: [.json(monitorJSON)])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "token", loader: loader)

        _ = try await client.startEntityMonitor(entityID: entityID)

        let request = try XCTUnwrap(loader.requests.first)
        XCTAssertEqual(request.url?.path, "/api/monitors/entity")
        XCTAssertEqual(request.httpMethod, "POST")
        let body = try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(request.httpBody)) as? [String: Any])
        XCTAssertEqual(body["entityId"] as? String, entityID.uuidString)
        XCTAssertNil(body["preset"])
    }

    func testPauseResumeAndSearchAgainUseExactCommandEndpoints() async throws {
        let loader = MockHTTPDataLoader(responses: [
            .json("", statusCode: 204),
            .json("", statusCode: 204),
            .json(
                #"{"summary":{"id":"33333333-3333-3333-3333-333333333333","status":"searching","title":"The Work","progress":null,"createdAt":"2026-07-01T12:00:00Z","updatedAt":"2026-07-11T12:00:00Z"},"candidates":[]}"#
            ),
        ])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "token", loader: loader)

        try await client.pauseMonitor(id: monitorID)
        try await client.resumeMonitor(id: monitorID)
        try await client.searchAcquisitionAgain(id: acquisitionID)

        XCTAssertEqual(
            loader.requests.map { $0.url?.path },
            [
                "/api/monitors/\(monitorID.uuidString.lowercased())/pause",
                "/api/monitors/\(monitorID.uuidString.lowercased())/resume",
                "/api/acquisitions/\(acquisitionID.uuidString.lowercased())/search",
            ])
        XCTAssertTrue(loader.requests.allSatisfy { $0.httpMethod == "POST" })
    }

    func testUnmonitorDeletesMonitorAndDecodesPrunedEntityOutcome() async throws {
        let loader = MockHTTPDataLoader(responses: [.json(#"{"entityPruned":true}"#)])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "token", loader: loader)

        let result = try await client.unmonitor(id: monitorID)

        XCTAssertTrue(result.entityPruned)
        let request = try XCTUnwrap(loader.requests.first)
        XCTAssertEqual(request.url?.path, "/api/monitors/\(monitorID.uuidString.lowercased())")
        XCTAssertEqual(request.httpMethod, "DELETE")
    }

    func testGroupingActionsUseWebParityEndpoints() async throws {
        let loader = MockHTTPDataLoader(responses: [
            .json("", statusCode: 204),
            .json(#"{"covered":3,"missing":2}"#),
        ])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "token", loader: loader)

        try await client.syncEntityContainer(entityID: entityID)
        let result = try await client.commitMissingChildren(entityID: entityID)

        XCTAssertEqual(result, EntityMissingChildrenSearchResponse(covered: 3, missing: 2))
        XCTAssertEqual(
            loader.requests.map { $0.url?.path },
            ["/api/requests/sync-container", "/api/requests/commit-missing-children"]
        )
        for request in loader.requests {
            XCTAssertEqual(request.httpMethod, "POST")
            let body = try XCTUnwrap(
                JSONSerialization.jsonObject(with: XCTUnwrap(request.httpBody)) as? [String: Any]
            )
            XCTAssertEqual(body["entityId"] as? String, entityID.uuidString)
        }
    }

    private var monitorStateJSON: String {
        """
        [{
          "entityId":"\(entityID.uuidString)",
          "canMonitor":true,
          "canRequest":true,
          "trackableProviders":["openlibrary"],
          "discoversChildren":false,
          "canSearchMissingChildren":false,
          "missingChildEntityKind":null,
          "monitor":\(monitorJSON),
          "latestAcquisition":{
            "id":"\(acquisitionID.uuidString)",
            "status":"downloading",
            "statusMessage":"Fetching release",
            "title":"The Work",
            "author":"Author",
            "series":null,
            "year":2026,
            "posterUrl":null,
            "progress":0.42,
            "createdAt":"2026-07-01T12:00:00Z",
            "updatedAt":"2026-07-11T12:00:00Z",
            "kind":"book",
            "entityId":"\(entityID.uuidString)"
          }
        }]
        """
    }

    private var monitorJSON: String {
        """
        {
          "id":"\(monitorID.uuidString)",
          "kind":"book",
          "acquisitionId":"\(acquisitionID.uuidString)",
          "status":"active",
          "title":"The Work",
          "author":"Author",
          "acquisitionStatus":"downloading",
          "createdAt":"2026-07-01T12:00:00Z",
          "updatedAt":"2026-07-11T12:00:00Z",
          "entityId":"\(entityID.uuidString)",
          "preset":"all"
        }
        """
    }
}
