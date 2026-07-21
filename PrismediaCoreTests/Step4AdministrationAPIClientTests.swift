import Foundation
import XCTest

@testable import PrismediaCore

final class Step4AdministrationAPIClientTests: XCTestCase {
    private let serverURL = URL(string: "https://media.example.test")!
    private let rootID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!

    func testFileMutationContractsUseRootRelativePathsAndExactMethods() async throws {
        let loader = MockHTTPDataLoader(responses: Array(repeating: .json(#"{"scansQueued":1}"#), count: 6))
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "token", loader: loader)

        _ = try await client.createAdministrativeFileFolder(rootID: rootID, parentPath: "Movies", name: "Arrival")
        _ = try await client.renameAdministrativeFile(rootID: rootID, path: "Movies/Arrival", name: "Arrival (2016)")
        _ = try await client.moveAdministrativeFile(
            sourceRootID: rootID,
            sourcePath: "Movies/Arrival (2016)",
            targetRootID: rootID,
            targetPath: "Favorites/Arrival (2016)"
        )
        _ = try await client.excludeAdministrativeFile(rootID: rootID, path: "Favorites/Arrival (2016)")
        _ = try await client.removeAdministrativeFileExclusion(rootID: rootID, path: "Favorites/Arrival (2016)")
        _ = try await client.deleteAdministrativeFile(rootID: rootID, path: "Favorites/Arrival (2016)")

        XCTAssertEqual(
            loader.requests.map(\.url?.path),
            [
                "/api/files/folders", "/api/files/rename", "/api/files/move",
                "/api/files/exclusions", "/api/files/exclusions", "/api/files",
            ]
        )
        XCTAssertEqual(loader.requests.map(\.httpMethod), ["POST", "PATCH", "POST", "POST", "DELETE", "DELETE"])
        XCTAssertEqual(try jsonBody(loader.requests[0])["parentPath"] as? String, "Movies")
        XCTAssertEqual(try jsonBody(loader.requests[1])["name"] as? String, "Arrival (2016)")
        XCTAssertEqual(try jsonBody(loader.requests[2])["targetPath"] as? String, "Favorites/Arrival (2016)")
        XCTAssertEqual(queryItem("hideNsfw", in: loader.requests[3]), "true")
        XCTAssertEqual(queryItem("rootId", in: loader.requests[5]), rootID.uuidString.lowercased())
    }

    func testFileDetailArchiveAndAuthenticatedDownloadsUseExactContracts() async throws {
        let archiveID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let detail =
            #"{"entry":{"rootId":"\#(rootID)","path":"Movies/Arrival.mkv","name":"Arrival.mkv","kind":"file","sizeBytes":1024,"mimeType":"video/x-matroska","modifiedAt":null,"excluded":false},"absolutePath":"/media/Movies/Arrival.mkv","createdAt":null,"linkedEntities":[],"canPreview":true,"directoryFileCount":null,"directoryTotalSizeBytes":null}"#
        let preparation =
            #"{"id":"\#(archiveID)","fileName":"Movies.zip","ready":true,"progressPercent":100,"processedFiles":2,"totalFiles":2,"error":null}"#
        let loader = MockHTTPDataLoader(responses: [
            .json(detail), .json(preparation, statusCode: 202), .json(preparation),
            .data(Data("file".utf8)), .data(Data("zip".utf8)),
        ])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "secret-token", loader: loader)

        let decoded = try await client.administrativeFileDetail(rootID: rootID, path: "Movies/Arrival.mkv")
        let started = try await client.prepareAdministrativeFileArchive(rootID: rootID, path: "Movies")
        _ = try await client.administrativeFileArchiveStatus(id: archiveID)
        let file = try await client.downloadAdministrativeFile(rootID: rootID, path: "Movies/Arrival.mkv")
        let archive = try await client.downloadAdministrativeFileArchive(id: archiveID)

        XCTAssertEqual(decoded.absolutePath, "/media/Movies/Arrival.mkv")
        XCTAssertEqual(started.fileName, "Movies.zip")
        XCTAssertEqual(file, Data("file".utf8))
        XCTAssertEqual(archive, Data("zip".utf8))
        XCTAssertEqual(
            loader.requests.map(\.url?.path),
            [
                "/api/files/detail", "/api/files/archives", "/api/files/archives/\(archiveID.uuidString.lowercased())",
                "/api/files/download", "/api/files/archives/\(archiveID.uuidString.lowercased())/content",
            ])
        XCTAssertTrue(
            loader.requests.suffix(2).allSatisfy {
                $0.value(forHTTPHeaderField: "Authorization") == "Bearer secret-token"
            })
        XCTAssertNil(queryItem("api_key", in: loader.requests[3]))
    }

    func testPluginCatalogMutationAndCredentialContracts() async throws {
        let provider =
            #"{"id":"tmdb","name":"TMDB","version":"1.2.0","installed":true,"enabled":true,"isNsfw":false,"supports":[],"auth":[],"missingAuthKeys":[],"updateAvailable":false,"availableVersion":null}"#
        let loader = MockHTTPDataLoader(responses: [
            .json("[\(provider)]"),
            .json(#"[{"providerId":"stash-film-updates","name":"Film Updates","version":"2026.07"}]"#),
            .json(provider), .json(provider), .json("", statusCode: 204), .json("", statusCode: 204),
        ])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "token", loader: loader)

        _ = try await client.listAdministrativePluginCatalog()
        _ = try await client.listAdministrativeStashScrapers()
        _ = try await client.installAdministrativePlugin(id: "tmdb")
        _ = try await client.updateAdministrativePlugin(id: "tmdb")
        try await client.saveAdministrativePluginAuth(id: "tmdb", values: ["api_key": "replacement", "pin": nil])
        try await client.removeAdministrativePlugin(id: "tmdb")

        XCTAssertEqual(
            loader.requests.map(\.url?.path),
            [
                "/api/plugins", "/api/plugins/stash-scrapers", "/api/plugins/tmdb", "/api/plugins/tmdb/update",
                "/api/plugins/tmdb/auth", "/api/plugins/tmdb",
            ])
        XCTAssertEqual(loader.requests.map(\.httpMethod), ["GET", "GET", "POST", "POST", "PUT", "DELETE"])
        let values = try XCTUnwrap(try jsonBody(loader.requests[4])["values"] as? [String: Any])
        XCTAssertEqual(values["api_key"] as? String, "replacement")
        XCTAssertTrue(values["pin"] is NSNull)
    }

    func testFilePathPolicyRejectsRootsTraversalAndInvalidSegments() {
        XCTAssertThrowsError(try AdministrativeFilePathPolicy.validatedName("../Movies"))
        XCTAssertThrowsError(try AdministrativeFilePathPolicy.validatedName("."))
        XCTAssertThrowsError(try AdministrativeFilePathPolicy.validatedRelativePath("/media/Movies"))
        XCTAssertThrowsError(try AdministrativeFilePathPolicy.validatedRelativePath("Movies/../../private"))
        XCTAssertEqual(try AdministrativeFilePathPolicy.validatedName(" Arrival "), "Arrival")
        XCTAssertEqual(try AdministrativeFilePathPolicy.validatedRelativePath(" Movies/Arrival "), "Movies/Arrival")
    }

    private func queryItem(_ name: String, in request: URLRequest) -> String? {
        URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems?.first { $0.name == name }?.value
    }

    private func jsonBody(_ request: URLRequest) throws -> [String: Any] {
        try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(request.httpBody)) as? [String: Any])
    }
}
