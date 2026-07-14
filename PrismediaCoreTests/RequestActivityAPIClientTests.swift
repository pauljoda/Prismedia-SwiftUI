import XCTest

@testable import PrismediaCore

final class RequestActivityAPIClientTests: XCTestCase {
    private let serverURL = URL(string: "https://media.example.test")!
    private let acquisitionID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    private let candidateID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    private let entityID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
    private let monitorID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
    private let blocklistID = UUID(uuidString: "55555555-5555-5555-5555-555555555555")!

    func testActivityListsUseExactRoutesQueriesAndSharedNsfwPolicy() async throws {
        let loader = MockHTTPDataLoader(responses: [
            .json("[]"),
            .json(#"{"items":[],"total":"0"}"#),
            .json(#"{"items":[],"total":0}"#),
            .json("[]"),
            .json("[]"),
        ])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "token", loader: loader)

        _ = try await client.listRequestActivityDownloads()
        _ = try await client.listRequestActivityWanted(.missing, page: 2, pageSize: 25, kind: .book)
        _ = try await client.listRequestActivityWanted(.cutoffUnmet, page: 3, pageSize: 10)
        _ = try await client.listRequestActivityHistory(limit: 200, entityID: entityID)
        _ = try await client.listRequestActivityBlocklist()

        XCTAssertEqual(
            loader.requests.map(\.url?.path),
            [
                "/api/acquisitions/downloads",
                "/api/monitors/missing",
                "/api/monitors/cutoff-unmet",
                "/api/acquisitions/history",
                "/api/acquisitions/blocklist",
            ])
        XCTAssertTrue(loader.requests.allSatisfy { $0.httpMethod == "GET" })
        XCTAssertEqual(queryItem("page", in: loader.requests[1]), "2")
        XCTAssertEqual(queryItem("pageSize", in: loader.requests[1]), "25")
        XCTAssertEqual(queryItem("kind", in: loader.requests[1]), "book")
        XCTAssertEqual(queryItem("hideNsfw", in: loader.requests[1]), "true")
        XCTAssertEqual(queryItem("hideNsfw", in: loader.requests[2]), "true")
        XCTAssertEqual(queryItem("limit", in: loader.requests[3]), "200")
        XCTAssertEqual(queryItem("entityId", in: loader.requests[3]), entityID.uuidString.lowercased())
    }

    func testWantedListUsesUpdatedSharedNsfwPreference() async throws {
        let loader = MockHTTPDataLoader(responses: [
            .json(#"{"items":[],"total":0}"#),
            .json(#"{"items":[],"total":0}"#),
        ])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "token", loader: loader)

        _ = try await client.listRequestActivityWanted(.missing)
        client.updateNsfwContentPreference(true)
        _ = try await client.listRequestActivityWanted(.missing)

        XCTAssertEqual(queryItem("hideNsfw", in: loader.requests[0]), "true")
        XCTAssertEqual(queryItem("hideNsfw", in: loader.requests[1]), "false")
    }

    func testActivityRowsDefensivelyDecodeEvolvingOptionalAndNumericFields() async throws {
        let loader = MockHTTPDataLoader(responses: [
            .json(
                """
                [{
                  "acquisitionId":"\(acquisitionID.uuidString)",
                  "kind":"future-kind",
                  "title":"Future Download",
                  "status":"downloading",
                  "statusMessage":null,
                  "progress":"0.42",
                  "updatedAt":"2026-07-12T12:00:00.1234567Z"
                }]
                """
            ),
            .json(
                """
                {"items":[{
                  "monitorId":"\(monitorID.uuidString)",
                  "acquisitionId":null,
                  "entityId":null,
                  "kind":"book",
                  "title":"Wanted Book",
                  "monitorStatus":"active",
                  "acquisitionStatus":null,
                  "lastSearchedAt":null,
                  "nextSearchAt":null,
                  "ownedQuality":null,
                  "cutoffQuality":null,
                  "barrenSearches":"3"
                }],"total":"1"}
                """
            ),
        ])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "token", loader: loader)

        let downloads = try await client.listRequestActivityDownloads()
        let wanted = try await client.listRequestActivityWanted(.missing)

        XCTAssertEqual(downloads.first?.kind.rawValue, "future-kind")
        XCTAssertEqual(downloads.first?.progress, 0.42)
        XCTAssertNil(downloads.first?.clientName)
        XCTAssertNil(downloads.first?.bookRendition)
        XCTAssertEqual(wanted.total, 1)
        XCTAssertEqual(wanted.items.first?.barrenSearches, 3)
        XCTAssertNil(wanted.items.first?.posterURL)
    }

    func testAcquisitionReviewAndCandidateCommandsUseExactContracts() async throws {
        let detail = acquisitionDetailJSON
        let loader = MockHTTPDataLoader(responses: [
            .json(detail),
            .json(detail),
            .json(detail),
            .json(detail),
            .json(detail),
            .json(detail),
            .json("", statusCode: 204),
        ])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "token", loader: loader)

        let loaded = try await client.fetchRequestActivityAcquisition(id: acquisitionID)
        _ = try await client.queueRequestActivityRelease(acquisitionID: acquisitionID, candidateID: candidateID)
        _ = try await client.blocklistRequestActivityCandidate(acquisitionID: acquisitionID, candidateID: candidateID)
        _ = try await client.researchRequestActivityAcquisition(id: acquisitionID)
        _ = try await client.retryRequestActivityImport(id: acquisitionID, allowFormatChange: true)
        _ = try await client.cancelRequestActivityAcquisition(id: acquisitionID)
        try await client.removeRequestActivityAcquisition(id: acquisitionID)

        XCTAssertEqual(loaded.summary.id, acquisitionID)
        XCTAssertEqual(loaded.candidates.first?.protocol.rawValue, "torrent")
        XCTAssertEqual(loaded.candidates.first?.rejections.first?.rawValue, "wrong-year")
        XCTAssertEqual(
            loader.requests.map(\.url?.path),
            [
                "/api/acquisitions/\(acquisitionID.uuidString.lowercased())",
                "/api/acquisitions/\(acquisitionID.uuidString.lowercased())/queue",
                "/api/acquisitions/\(acquisitionID.uuidString.lowercased())/candidates/\(candidateID.uuidString.lowercased())/blocklist",
                "/api/acquisitions/\(acquisitionID.uuidString.lowercased())/search",
                "/api/acquisitions/\(acquisitionID.uuidString.lowercased())/import",
                "/api/acquisitions/\(acquisitionID.uuidString.lowercased())/cancel",
                "/api/acquisitions/\(acquisitionID.uuidString.lowercased())",
            ])
        XCTAssertEqual(loader.requests.map(\.httpMethod), ["GET", "POST", "POST", "POST", "POST", "POST", "DELETE"])

        let queueBody = try body(in: loader.requests[1])
        XCTAssertEqual(queueBody["candidateId"] as? String, candidateID.uuidString)
        let retryBody = try body(in: loader.requests[4])
        XCTAssertEqual(retryBody["allowFormatChange"] as? Bool, true)
        XCTAssertNil(loader.requests[2].httpBody)
        XCTAssertNil(loader.requests[3].httpBody)
        XCTAssertNil(loader.requests[5].httpBody)
    }

    func testTransferFilesHistoryAndBlocklistDecodeExactContracts() async throws {
        let loader = MockHTTPDataLoader(responses: [
            .json("", statusCode: 204),
            .json(
                #"{"progress":"0.5","state":"downloading","totalSizeBytes":"1024","downloadSpeedBytesPerSecond":"256.5","etaSeconds":"4","seeds":"7","peers":2,"savePath":"/downloads/item","pieceStates":[0,"1",2]}"#
            ),
            .json(#"{"imported":false,"files":[{"name":"item.mkv","sizeBytes":"1024","progress":"0.5"}]}"#),
            .json("[\(historyJSON)]"),
            .json("[\(blocklistJSON)]"),
            .json("", statusCode: 204),
        ])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "token", loader: loader)

        let absentTransfer = try await client.fetchRequestActivityTransfer(id: acquisitionID)
        let transfer = try await client.fetchRequestActivityTransfer(id: acquisitionID)
        let files = try await client.fetchRequestActivityFiles(id: acquisitionID)
        let history = try await client.listRequestActivityHistory()
        let blocklist = try await client.listRequestActivityBlocklist()
        try await client.removeRequestActivityBlocklistEntry(id: blocklistID)

        XCTAssertNil(absentTransfer)
        XCTAssertEqual(transfer?.totalSizeBytes, 1_024)
        XCTAssertEqual(transfer?.pieceStates, [0, 1, 2])
        XCTAssertEqual(files.files.first?.name, "item.mkv")
        XCTAssertEqual(files.files.first?.sizeBytes, 1_024)
        XCTAssertEqual(history.first?.event.rawValue, "grabbed")
        XCTAssertEqual(blocklist.first?.reason.rawValue, "failed")
        XCTAssertEqual(
            loader.requests[5].url?.path, "/api/acquisitions/blocklist/\(blocklistID.uuidString.lowercased())")
        XCTAssertEqual(loader.requests[5].httpMethod, "DELETE")
    }

    func testManualTorrentUploadUsesMultipartFileContract() async throws {
        let loader = MockHTTPDataLoader(responses: [.json(acquisitionDetailJSON)])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "token", loader: loader)
        let torrent = Data([0x64, 0x34, 0x3a, 0x69, 0x6e, 0x66, 0x6f])

        _ = try await client.uploadRequestActivityTorrent(
            RequestActivityManualTorrentUpload(
                acquisitionID: acquisitionID,
                fileName: "Example.torrent",
                data: torrent
            ))

        let request = try XCTUnwrap(loader.requests.first)
        XCTAssertEqual(
            request.url?.path,
            "/api/acquisitions/\(acquisitionID.uuidString.lowercased())/upload-torrent"
        )
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer token")
        let contentType = try XCTUnwrap(request.value(forHTTPHeaderField: "Content-Type"))
        XCTAssertTrue(contentType.hasPrefix("multipart/form-data; boundary=PrismediaBoundary-"))
        let body = try XCTUnwrap(request.httpBody)
        let text = String(decoding: body, as: UTF8.self)
        XCTAssertTrue(text.contains("name=\"file\"; filename=\"Example.torrent\""))
        XCTAssertTrue(text.contains("Content-Type: application/x-bittorrent"))
        XCTAssertTrue(body.range(of: torrent) != nil)
    }

    func testRequestActivityPortIncludesExistingMonitorCommands() async throws {
        let loader = MockHTTPDataLoader(responses: [
            .json("", statusCode: 204),
            .json("", statusCode: 204),
            .json(#"{"entityPruned":false}"#),
        ])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "token", loader: loader)
        let port: any RequestActivityServicing = client

        try await port.pauseMonitor(id: monitorID)
        try await port.resumeMonitor(id: monitorID)
        let outcome = try await port.unmonitor(id: monitorID)

        XCTAssertFalse(outcome.entityPruned)
    }

    private var acquisitionDetailJSON: String {
        """
        {
          "summary":{
            "id":"\(acquisitionID.uuidString)",
            "status":"awaiting-selection",
            "statusMessage":null,
            "title":"Example",
            "author":null,
            "series":null,
            "year":"2026",
            "posterUrl":null,
            "progress":null,
            "createdAt":"2026-07-12T10:00:00Z",
            "updatedAt":"2026-07-12T11:00:00Z"
          },
          "candidates":[{
            "id":"\(candidateID.uuidString)",
            "indexerName":"Prowlarr",
            "title":"Example.2026",
            "sizeBytes":"2048",
            "seeders":"8",
            "peers":2,
            "protocol":"torrent",
            "accepted":false,
            "score":"12.5",
            "rejections":["wrong-year"],
            "infoUrl":null,
            "publishedAt":null
          }]
        }
        """
    }

    private var historyJSON: String {
        #"{"id":"66666666-6666-6666-6666-666666666666","acquisitionId":null,"entityId":null,"kind":"movie","event":"grabbed","title":"Example","releaseTitle":null,"indexerName":null,"downloadClientName":null,"qualityCode":null,"formatScore":null,"message":null,"createdAt":"2026-07-12T12:00:00Z"}"#
    }

    private var blocklistJSON: String {
        """
        {"id":"\(blocklistID.uuidString)","reason":"failed","title":null,"indexerName":null,"infoHash":null,"acquisitionId":null,"message":null,"createdAt":"2026-07-12T12:00:00Z"}
        """
    }

    private func queryItem(_ name: String, in request: URLRequest) -> String? {
        URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == name })?
            .value
    }

    private func body(in request: URLRequest) throws -> [String: Any] {
        try XCTUnwrap(
            JSONSerialization.jsonObject(with: XCTUnwrap(request.httpBody)) as? [String: Any]
        )
    }
}
