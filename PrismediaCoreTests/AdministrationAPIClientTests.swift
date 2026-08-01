import XCTest

@testable import PrismediaCore

final class AdministrationAPIClientTests: XCTestCase {
    private let serverURL = URL(string: "https://media.example.test")!
    private let rootID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    private let userID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    private let sessionID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
    private let backupID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!

    func testAccountMutationsAndSessionRevocationUseSelfServiceContracts() async throws {
        let loader = MockHTTPDataLoader(responses: [
            .json(userJSON),
            .json("", statusCode: 204),
            .json(
                #"{"items":[{"id":"\#(sessionID)","client":"Prismedia iOS","deviceName":"iPhone","deviceId":"device-1","applicationVersion":"1.0","createdAt":"2026-07-01T12:00:00Z","lastSeenAt":"2026-07-16T12:00:00Z","isCurrent":true}]}"#
            ),
            .json("", statusCode: 204),
        ])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "secret-token", loader: loader)

        _ = try await client.updateOwnProfile(displayName: "Paul Davis")
        try await client.changeOwnPassword(currentPassword: "old-secret", newPassword: "new-secret")
        let sessions = try await client.listOwnSessions()
        try await client.revokeOwnSession(id: sessionID)

        XCTAssertEqual(sessions.first?.isCurrent, true)
        XCTAssertEqual(
            loader.requests.map(\.url?.path),
            [
                "/api/auth/me", "/api/auth/password", "/api/auth/sessions",
                "/api/auth/sessions/\(sessionID.uuidString.lowercased())",
            ])
        XCTAssertEqual(loader.requests.map(\.httpMethod), ["PATCH", "POST", "GET", "DELETE"])
        XCTAssertEqual(try jsonBody(loader.requests[0])["displayName"] as? String, "Paul Davis")
        let passwordBody = try jsonBody(loader.requests[1])
        XCTAssertEqual(passwordBody["currentPassword"] as? String, "old-secret")
        XCTAssertEqual(passwordBody["newPassword"] as? String, "new-secret")
    }

    func testLibraryRootWorkflowUsesBrowseCreatePatchRescanAccessAndConfigurationOnlyDeleteContracts() async throws {
        let loader = MockHTTPDataLoader(responses: [
            .json(#"{"path":"/media","parentPath":"/","directories":[{"name":"Movies","path":"/media/movies"}]}"#),
            .json(rootJSON),
            .json(rootJSON),
            .json(#"{"scansQueued":1}"#),
            .json("", statusCode: 204),
            .json(#"{"ok":true}"#),
        ])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "token", loader: loader)
        let mutation = AdministrativeLibraryRootMutation(
            path: "/media/movies", label: "Movies", enabled: true, recursive: true,
            scanVideos: true, scanImages: false, scanAudio: false, scanBooks: false,
            isNsfw: false, autoIdentify: true
        )

        _ = try await client.browseAdministrativeLibraryPath("/media")
        _ = try await client.createAdministrativeLibraryRoot(mutation)
        _ = try await client.updateAdministrativeLibraryRoot(id: rootID, mutation: mutation)
        _ = try await client.rescanAdministrativeFiles(rootID: rootID, path: nil)
        try await client.replaceAdministrativeLibraryAccess(rootID: rootID, userIDs: [userID])
        try await client.deleteAdministrativeLibraryRoot(id: rootID)

        XCTAssertEqual(
            loader.requests.map(\.url?.path),
            [
                "/api/libraries/browse", "/api/libraries", "/api/libraries/\(rootID.uuidString.lowercased())",
                "/api/files/rescan", "/api/libraries/\(rootID.uuidString.lowercased())/access",
                "/api/libraries/\(rootID.uuidString.lowercased())",
            ])
        XCTAssertEqual(loader.requests.map(\.httpMethod), ["GET", "POST", "PATCH", "POST", "PUT", "DELETE"])
        XCTAssertEqual(try jsonBody(loader.requests[4])["userIds"] as? [String], [userID.uuidString])
    }

    func testLibraryInventoryDoesNotRevealNsfwRootsUntilTheViewPreferenceIsEnabled() async throws {
        let response = "[\(rootJSON),\(nsfwRootJSON)]"
        let loader = MockHTTPDataLoader(responses: [.json(response), .json(response)])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "token", loader: loader)

        let hiddenInventory = try await client.listAdministrativeLibraryRoots()
        client.updateNsfwContentPreference(true)
        let visibleInventory = try await client.listAdministrativeLibraryRoots()

        XCTAssertEqual(hiddenInventory.map(\.label), ["Movies"])
        XCTAssertEqual(visibleInventory.map(\.label), ["Movies", "Private"])
    }

    func testUserAdministrationUsesCrudPasswordAndAtomicLibraryAccessContracts() async throws {
        let loader = MockHTTPDataLoader(responses: [
            .json("{\"items\":[\(userJSON)]}"),
            .json(userJSON),
            .json(userJSON),
            .json("", statusCode: 204),
            .json("", statusCode: 204),
            .json("", statusCode: 204),
        ])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "token", loader: loader)

        _ = try await client.listAdministrativeUsers()
        _ = try await client.createAdministrativeUser(
            AdministrativeUserCreateMutation(username: "reader", password: "eightchars", displayName: "Reader")
        )
        _ = try await client.updateAdministrativeUser(
            id: userID,
            mutation: AdministrativeUserUpdateMutation(displayName: "Reader Two", allowNsfw: true)
        )
        try await client.resetAdministrativeUserPassword(id: userID, newPassword: "another-secret")
        try await client.replaceAdministrativeUserLibraryAccess(userID: userID, rootIDs: [rootID])
        try await client.deleteAdministrativeUser(id: userID)

        XCTAssertEqual(loader.requests.map(\.httpMethod), ["GET", "POST", "PATCH", "POST", "PUT", "DELETE"])
        XCTAssertNil(try jsonBody(loader.requests[1])["allowSfw"])
        XCTAssertEqual(try jsonBody(loader.requests[1])["allowNsfw"] as? Bool, false)
        XCTAssertNil(try jsonBody(loader.requests[2])["allowSfw"])
        XCTAssertEqual(try jsonBody(loader.requests[2])["allowNsfw"] as? Bool, true)
        XCTAssertEqual(loader.requests[3].url?.path, "/api/users/\(userID.uuidString.lowercased())/password")
        XCTAssertEqual(loader.requests[4].url?.path, "/api/users/\(userID.uuidString.lowercased())/library-access")
    }

    func testDiagnosticsAndBackupRestoreUsePublicHealthAndDestructiveSchedulingContracts() async throws {
        let loader = MockHTTPDataLoader(responses: [
            .json(#"{"status":"ok","runtime":"dotnet"}"#),
            .json(
                #"{"status":"online","workerId":"worker-1","lastSeenAt":"2026-07-16T12:00:00Z","staleAfterSeconds":45}"#
            ),
            .json(backupListJSON),
            .json(#"{"enqueued":4,"skipped":1}"#),
            .json(#"{"enqueued":3,"skipped":2}"#),
            .json(#"{"backupId":"\#(backupID)","requestedAt":"2026-07-16T12:05:00Z","restartScheduled":true}"#),
            .json(#"{"restorePending":true,"restoreFailed":false,"error":null}"#),
        ])
        let client = PrismediaAPIClient(serverURL: serverURL, accessToken: "token", loader: loader)

        _ = try await client.health()
        _ = try await client.administrativeWorkerHealth()
        let backups = try await client.listAdministrativeDatabaseBackups()
        _ = try await client.rebuildAdministrativePreviews()
        _ = try await client.backfillAdministrativeFingerprints()
        _ = try await client.restoreAdministrativeDatabaseBackup(id: backupID, confirmationText: "DESTROY AND RESTORE")
        _ = try await client.administrativeDatabaseRestoreStatus()

        XCTAssertEqual(backups.restoreConfirmationText, "DESTROY AND RESTORE")
        XCTAssertEqual(loader.requests[5].url?.path, "/api/settings/database-backups/restore")
        XCTAssertEqual(try jsonBody(loader.requests[5])["backupId"] as? String, backupID.uuidString)
        XCTAssertEqual(loader.requests[6].url?.path, "/api/health/database-restore")
    }

    private var userJSON: String {
        #"{"id":"\#(userID)","username":"reader","displayName":"Reader","role":"member","allowNsfw":false,"canCreateLibraries":false,"enabled":true,"lastLoginAt":null,"createdAt":"2026-07-01T12:00:00Z","updatedAt":"2026-07-01T12:00:00Z","libraryRootIds":[]}"#
    }

    private var rootJSON: String {
        #"{"id":"\#(rootID)","path":"/media/movies","label":"Movies","enabled":true,"recursive":true,"scanVideos":true,"scanImages":false,"scanAudio":false,"scanBooks":false,"isNsfw":false,"lastScannedAt":null,"createdAt":"2026-07-01T12:00:00Z","updatedAt":"2026-07-01T12:00:00Z","autoIdentify":true,"createdByUserId":null,"accessUserIds":[]}"#
    }

    private var nsfwRootJSON: String {
        rootJSON
            .replacingOccurrences(of: #""label":"Movies""#, with: #""label":"Private""#)
            .replacingOccurrences(of: #""isNsfw":false"#, with: #""isNsfw":true"#)
    }

    private var backupListJSON: String {
        #"{"backups":[{"id":"\#(backupID)","fileName":"manual.sqlite","backupPath":"/data/manual.sqlite","status":"completed","isManual":true,"sizeBytes":1024,"createdAt":"2026-07-16T12:00:00Z","completedAt":"2026-07-16T12:00:02Z","expiresAt":null,"error":null}],"nextAutomaticBackupAt":"2026-07-17T03:00:00Z","backupDirectory":"/data/backups","automaticRetentionDays":7,"restoreConfirmationText":"DESTROY AND RESTORE"}"#
    }

    private func jsonBody(_ request: URLRequest) throws -> [String: Any] {
        try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(request.httpBody)) as? [String: Any])
    }
}

final class AdministrativeFileAPIClientTests: XCTestCase {
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
            ])
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
        XCTAssertNil(queryItem("access_token", in: loader.requests[3]))
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
