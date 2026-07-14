import Foundation
import XCTest

@testable import PrismediaCore

final class CollectionManagementAPIClientTests: XCTestCase {
    private let serverURL = URL(string: "https://example.com/base")!

    func testFetchMembershipsRetainsTheCompleteOrderedRowContract() async throws {
        let collectionID = UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!
        let membershipID = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
        let secondMembershipID = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
        let entityID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let secondEntityID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let loader = MockHTTPDataLoader(responses: [
            .json(
                """
                {
                  "items": [
                    {
                      "id": "\(membershipID)",
                      "collectionId": "\(collectionID)",
                      "entityType": "movie",
                      "entityId": "\(entityID)",
                      "source": "dynamic",
                      "sortOrder": 7,
                      "addedAt": "2026-07-11T12:34:56.789Z",
                      "entity": { "id": "\(entityID)", "kind": "movie", "title": "Arrival" }
                    },
                    {
                      "id": "\(secondMembershipID)",
                      "collectionId": "\(collectionID)",
                      "entityType": "audio-track",
                      "entityId": "\(secondEntityID)",
                      "source": "manual",
                      "sortOrder": 2,
                      "addedAt": "2026-07-10T12:00:00Z",
                      "entity": { "id": "\(secondEntityID)", "kind": "audio-track", "title": "On the Nature of Daylight" }
                    }
                  ]
                }
                """)
        ])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "token", loader: loader)

        let memberships = try await client.fetchCollectionMemberships(collectionID: collectionID)

        XCTAssertEqual(memberships.map(\.id), [membershipID, secondMembershipID])
        let membership = try XCTUnwrap(memberships.first)
        XCTAssertEqual(membership.id, membershipID)
        XCTAssertEqual(membership.collectionID, collectionID)
        XCTAssertEqual(membership.entityType, .movie)
        XCTAssertEqual(membership.entityID, entityID)
        XCTAssertEqual(membership.source, .dynamic)
        XCTAssertEqual(membership.sortOrder, 7)
        XCTAssertEqual(membership.addedAt.timeIntervalSince1970, 1_783_773_296.789, accuracy: 0.001)
        XCTAssertEqual(membership.entity.title, "Arrival")

        let request = try XCTUnwrap(loader.requests.first)
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(
            request.url?.path,
            "/base/api/collections/\(collectionID.uuidString.lowercased())/items"
        )
        XCTAssertEqual(queryItem("hideNsfw", in: request), "true")
    }

    func testCreateAndUpdateCollectionsUseTheExactWriteContract() async throws {
        let collectionID = UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!
        let coverItemID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let response =
            """
            {
              "id": "\(collectionID)",
              "kind": "collection",
              "title": "Road Trip",
              "capabilities": [],
              "mode": "hybrid",
              "ruleTreeJson": "{\\"type\\":\\"group\\"}",
              "coverMode": "item",
              "coverItemId": "\(coverItemID)",
              "lastRefreshedAt": "2026-07-11T13:00:00Z"
            }
            """
        let loader = MockHTTPDataLoader(responses: [.json(response, statusCode: 201), .json(response)])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "token", loader: loader)
        let write = CollectionWriteRequest(
            title: "Road Trip",
            description: "Driving music",
            mode: .hybrid,
            ruleTreeJSON: #"{"type":"group"}"#,
            coverMode: .item,
            coverItemID: coverItemID,
            isNsfw: false
        )

        let created = try await client.createCollection(write)
        let updated = try await client.updateCollection(id: collectionID, request: write)

        XCTAssertEqual(created.id, collectionID)
        XCTAssertEqual(created.mode, .hybrid)
        XCTAssertEqual(created.ruleTreeJSON, #"{"type":"group"}"#)
        XCTAssertEqual(created.coverMode, .item)
        XCTAssertEqual(created.coverItemID, coverItemID)
        XCTAssertNotNil(created.lastRefreshedAt)
        XCTAssertEqual(updated, created)

        XCTAssertEqual(loader.requests[0].httpMethod, "POST")
        XCTAssertEqual(loader.requests[0].url?.path, "/base/api/collections")
        XCTAssertEqual(loader.requests[1].httpMethod, "PUT")
        XCTAssertEqual(
            loader.requests[1].url?.path,
            "/base/api/collections/\(collectionID.uuidString.lowercased())"
        )
        for request in loader.requests {
            let body = try jsonBody(request)
            XCTAssertEqual(body["title"] as? String, "Road Trip")
            XCTAssertEqual(body["description"] as? String, "Driving music")
            XCTAssertEqual(body["mode"] as? String, "hybrid")
            XCTAssertEqual(body["ruleTreeJson"] as? String, #"{"type":"group"}"#)
            XCTAssertEqual(body["coverMode"] as? String, "item")
            XCTAssertEqual(body["coverItemId"] as? String, coverItemID.uuidString)
            XCTAssertEqual(body["isNsfw"] as? Bool, false)
        }
    }

    func testDeleteAddRemoveAndReorderUseMembershipRowIdentifiers() async throws {
        let collectionID = UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!
        let entityID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let firstMembershipID = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
        let secondMembershipID = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
        let loader = MockHTTPDataLoader(responses: [
            .json(#"{"count":1}"#),
            .json(#"{"count":1}"#),
            .json(#"{"count":2}"#),
            .json("{\"id\":\"\(collectionID)\"}"),
        ])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "token", loader: loader)

        let added = try await client.addCollectionMembers(
            collectionID: collectionID,
            items: [CollectionEntityReference(entityType: .movie, entityID: entityID)]
        )
        let removed = try await client.removeCollectionMembers(
            collectionID: collectionID,
            itemIDs: [firstMembershipID]
        )
        let reordered = try await client.reorderCollectionMembers(
            collectionID: collectionID,
            itemIDs: [secondMembershipID, firstMembershipID]
        )
        let deletedID = try await client.deleteCollection(id: collectionID)

        XCTAssertEqual(added, 1)
        XCTAssertEqual(removed, 1)
        XCTAssertEqual(reordered, 2)
        XCTAssertEqual(deletedID, collectionID)

        XCTAssertEqual(loader.requests.map(\.httpMethod), ["POST", "POST", "PATCH", "DELETE"])
        XCTAssertEqual(
            loader.requests.map { $0.url?.path },
            [
                "/base/api/collections/\(collectionID.uuidString.lowercased())/items",
                "/base/api/collections/\(collectionID.uuidString.lowercased())/items/remove",
                "/base/api/collections/\(collectionID.uuidString.lowercased())/items/reorder",
                "/base/api/collections/\(collectionID.uuidString.lowercased())",
            ]
        )

        let addBody = try jsonBody(loader.requests[0])
        let items = try XCTUnwrap(addBody["items"] as? [[String: Any]])
        XCTAssertEqual(items.first?["entityType"] as? String, "movie")
        XCTAssertEqual(items.first?["entityId"] as? String, entityID.uuidString)
        XCTAssertEqual(try jsonBody(loader.requests[1])["itemIds"] as? [String], [firstMembershipID.uuidString])
        XCTAssertEqual(
            try jsonBody(loader.requests[2])["itemIds"] as? [String],
            [secondMembershipID.uuidString, firstMembershipID.uuidString]
        )
    }

    private func jsonBody(_ request: URLRequest) throws -> [String: Any] {
        try XCTUnwrap(
            JSONSerialization.jsonObject(with: XCTUnwrap(request.httpBody)) as? [String: Any]
        )
    }

    private func queryItem(_ name: String, in request: URLRequest) -> String? {
        guard let url = request.url else { return nil }
        return URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first { $0.name == name }?
            .value
    }
}
