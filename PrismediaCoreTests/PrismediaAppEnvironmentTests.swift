import XCTest

@testable import PrismediaCore

@MainActor
final class PrismediaAppEnvironmentTests: XCTestCase {
    private let serverURL = URL(string: "https://media.example.test")!

    private var storedUser: UserAccount {
        UserAccount(
            id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!, username: "paul", displayName: "Paul",
            role: .admin)
    }

    private var storedSession: AuthSession {
        AuthSession(serverURL: serverURL, accessToken: "stored-token", user: storedUser)
    }

    private let loginResponseJSON = """
        {
          "accessToken": "fresh-token",
          "user": {
            "id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
            "username": "paul",
            "displayName": "Paul",
            "role": "admin",
            "allowSfw": true,
            "allowNsfw": true,
            "canCreateLibraries": true,
            "enabled": true,
            "lastLoginAt": null,
            "createdAt": "2026-07-06T20:00:00Z",
            "updatedAt": "2026-07-06T20:00:00Z"
          }
        }
        """

    private func makeModel(
        store: RecordingSessionStore,
        loader: HTTPDataLoading,
        initialSession: AuthSession? = nil,
        serverStore: RecordingServerPreferenceStore = RecordingServerPreferenceStore(),
        nsfwStore: RecordingNsfwPreferenceStore = RecordingNsfwPreferenceStore()
    ) -> PrismediaAppEnvironment {
        PrismediaAppEnvironment(
            sessionStore: store,
            serverPreferenceStore: serverStore,
            nsfwPreferenceStore: nsfwStore,
            clientFactory: { PrismediaAPIClient(serverURL: $0, loader: loader) },
            initialSession: initialSession,
            restoreOnInit: false
        )
    }

    func testNsfwContentIsOffByDefaultForAnEligibleUser() {
        let eligibleUser = UserAccount(
            id: storedUser.id,
            username: storedUser.username,
            displayName: storedUser.displayName,
            role: storedUser.role,
            allowNsfw: true
        )
        let session = AuthSession(serverURL: serverURL, accessToken: "token", user: eligibleUser)
        let model = makeModel(
            store: RecordingSessionStore(savedSession: session),
            loader: MockHTTPDataLoader(responses: []),
            initialSession: session
        )

        XCTAssertFalse(model.allowsNsfwContent)
        XCTAssertFalse(model.client?.allowsNsfwContent ?? true)
    }

    func testStoredNsfwPreferenceRestoresForTheSameEligibleUser() {
        let eligibleUser = UserAccount(
            id: storedUser.id,
            username: storedUser.username,
            displayName: storedUser.displayName,
            role: storedUser.role,
            allowNsfw: true
        )
        let session = AuthSession(serverURL: serverURL, accessToken: "token", user: eligibleUser)
        let model = makeModel(
            store: RecordingSessionStore(savedSession: session),
            loader: MockHTTPDataLoader(responses: []),
            initialSession: session,
            nsfwStore: RecordingNsfwPreferenceStore(savedValues: [eligibleUser.id: true])
        )

        XCTAssertTrue(model.allowsNsfwContent)
        XCTAssertTrue(model.client?.allowsNsfwContent ?? false)
    }

    func testEnablingNsfwContentPersistsPerUserAndReconfiguresEveryRequestClient() {
        let eligibleUser = UserAccount(
            id: storedUser.id,
            username: storedUser.username,
            displayName: storedUser.displayName,
            role: storedUser.role,
            allowNsfw: true
        )
        let session = AuthSession(serverURL: serverURL, accessToken: "token", user: eligibleUser)
        let nsfwStore = RecordingNsfwPreferenceStore()
        let model = makeModel(
            store: RecordingSessionStore(savedSession: session),
            loader: MockHTTPDataLoader(responses: []),
            initialSession: session,
            nsfwStore: nsfwStore
        )

        model.setAllowsNsfwContent(true)

        XCTAssertTrue(model.allowsNsfwContent)
        XCTAssertTrue(model.client?.allowsNsfwContent ?? false)
        XCTAssertEqual(nsfwStore.savedValues[eligibleUser.id], true)
        XCTAssertEqual(model.contentRevision, 1)
        XCTAssertEqual(model.entityListRevision, 1)
    }

    func testUserWithoutNsfwPermissionCannotEnableTheGlobalPreference() {
        let model = makeModel(
            store: RecordingSessionStore(savedSession: storedSession),
            loader: MockHTTPDataLoader(responses: []),
            initialSession: storedSession
        )

        model.setAllowsNsfwContent(true)

        XCTAssertFalse(model.allowsNsfwContent)
        XCTAssertFalse(model.client?.allowsNsfwContent ?? true)
    }

    func testEntityMutationInvalidatesRetainedEntityLists() {
        let model = makeModel(store: RecordingSessionStore(), loader: MockHTTPDataLoader(responses: []))

        XCTAssertEqual(model.entityListRevision, 0)
        XCTAssertEqual(model.contentRevision, 0)

        model.entityDidMutate()

        XCTAssertEqual(model.entityListRevision, 1)
        XCTAssertEqual(model.contentRevision, 1)
    }

    func testManualReloadInvalidatesAllRetainedContent() {
        let model = makeModel(store: RecordingSessionStore(), loader: MockHTTPDataLoader(responses: []))

        model.reloadContent()

        XCTAssertEqual(model.entityListRevision, 1)
        XCTAssertEqual(model.contentRevision, 1)
    }

    func testSuccessfulProbeRemembersServerBeforeLogin() async throws {
        let serverStore = RecordingServerPreferenceStore()
        let loader = MockHTTPDataLoader(responses: [
            .json("{ \"needsSetup\": false, \"hasUsers\": true }")
        ])
        let model = makeModel(
            store: RecordingSessionStore(),
            loader: loader,
            serverStore: serverStore
        )

        _ = try await model.probeServer(urlText: "media.example.test")

        XCTAssertEqual(model.lastServerURL, serverURL)
        XCTAssertEqual(serverStore.savedURL, serverURL)
    }

    func testVolatileServerPreferenceStartsEmptyAndDoesNotCrossStoreInstances() {
        let store = VolatileServerPreferenceStore()

        XCTAssertNil(store.load())

        store.save(serverURL)

        XCTAssertEqual(store.load(), serverURL)
        XCTAssertNil(VolatileServerPreferenceStore().load())
    }

    func testSignInSavesSessionAndBuildsAuthenticatedClient() async throws {
        let store = RecordingSessionStore()
        let loader = MockHTTPDataLoader(responses: [.json(loginResponseJSON)])
        let model = makeModel(store: store, loader: loader)

        try await model.signIn(
            server: try ServerAddress(text: "media.example.test"),
            username: "paul",
            password: "hunter22"
        )

        XCTAssertEqual(model.session?.accessToken, "fresh-token")
        XCTAssertEqual(model.client?.accessToken, "fresh-token")
        XCTAssertEqual(store.savedSession?.accessToken, "fresh-token")
        XCTAssertEqual(store.saveCount, 1)
    }

    func testSuccessfulSignInRemainsUsableWhenSecurePersistenceIsUnavailable() async throws {
        let store = RecordingSessionStore(saveError: KeychainSessionStoreError.unhandledStatus(-34018))
        let loader = MockHTTPDataLoader(responses: [.json(loginResponseJSON)])
        let model = makeModel(store: store, loader: loader)

        try await model.signIn(
            server: try ServerAddress(text: "media.example.test"),
            username: "paul",
            password: "hunter22"
        )

        XCTAssertEqual(model.session?.accessToken, "fresh-token")
        XCTAssertEqual(model.client?.accessToken, "fresh-token")
        XCTAssertNil(store.savedSession)
        XCTAssertEqual(store.saveCount, 1)
    }

    func testSignInFailureLeavesModelSignedOut() async {
        let store = RecordingSessionStore()
        let loader = MockHTTPDataLoader(responses: [
            .json(
                """
                { "code": "invalid_credentials", "message": "Invalid username or password." }
                """, statusCode: 401)
        ])
        let model = makeModel(store: store, loader: loader)

        do {
            try await model.signIn(
                server: try ServerAddress(text: "media.example.test"),
                username: "paul",
                password: "wrong"
            )
            XCTFail("Expected sign-in to fail.")
        } catch {
            XCTAssertEqual(error.localizedDescription, "Invalid username or password.")
        }

        XCTAssertNil(model.session)
        XCTAssertNil(model.client)
        XCTAssertEqual(store.saveCount, 0)
    }

    func testVerifySessionClearsDeadSession() async {
        let store = RecordingSessionStore(savedSession: storedSession)
        let loader = MockHTTPDataLoader(responses: [
            .json(
                """
                { "code": "authentication_required", "message": "Authentication is required." }
                """, statusCode: 401)
        ])
        let model = makeModel(store: store, loader: loader, initialSession: storedSession)

        XCTAssertNotNil(model.client)

        await model.verifyCurrentSession()

        XCTAssertNil(model.session)
        XCTAssertNil(model.client)
        XCTAssertNil(store.savedSession)
        XCTAssertEqual(store.clearCount, 1)
    }

    func testVerifySessionKeepsSessionWhenServerIsUnreachable() async {
        let store = RecordingSessionStore(savedSession: storedSession)
        let loader = FailingHTTPDataLoader(error: URLError(.cannotConnectToHost))
        let model = makeModel(store: store, loader: loader, initialSession: storedSession)

        await model.verifyCurrentSession()

        XCTAssertEqual(model.session, storedSession)
        XCTAssertNotNil(model.client)
        XCTAssertEqual(store.clearCount, 0)
    }

    func testVerifySessionRefreshesChangedUser() async throws {
        let store = RecordingSessionStore(savedSession: storedSession)
        let loader = MockHTTPDataLoader(responses: [
            .json(
                """
                {
                  "id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
                  "username": "paul",
                  "displayName": "Paul Renamed",
                  "role": "admin",
                  "allowSfw": true,
                  "allowNsfw": false,
                  "canCreateLibraries": false,
                  "enabled": true,
                  "lastLoginAt": null,
                  "createdAt": "2026-07-06T20:00:00Z",
                  "updatedAt": "2026-07-07T20:00:00Z"
                }
                """)
        ])
        let model = makeModel(store: store, loader: loader, initialSession: storedSession)

        await model.verifyCurrentSession()

        XCTAssertEqual(model.session?.user.displayName, "Paul Renamed")
        XCTAssertEqual(model.session?.accessToken, "stored-token")
        XCTAssertEqual(store.savedSession?.user.displayName, "Paul Renamed")
    }

    func testRestoreSessionLoadsStoredSession() async {
        let store = RecordingSessionStore(savedSession: storedSession)
        let model = makeModel(store: store, loader: MockHTTPDataLoader(responses: []))

        await model.restoreSession()

        XCTAssertEqual(model.session, storedSession)
        XCTAssertNotNil(model.client)
        XCTAssertFalse(model.isRestoringSession)
    }

    func testSignOutClearsStoreAndCallsLogout() async {
        let store = RecordingSessionStore(savedSession: storedSession)
        let loader = MockHTTPDataLoader(responses: [.json("", statusCode: 204)])
        let model = makeModel(store: store, loader: loader, initialSession: storedSession)

        await model.signOut()

        XCTAssertNil(model.session)
        XCTAssertNil(model.client)
        XCTAssertNil(store.savedSession)
        XCTAssertEqual(store.clearCount, 1)
        XCTAssertEqual(loader.requests.first?.url?.path, "/api/auth/logout")
    }
}

private final class RecordingSessionStore: SessionStoring {
    var savedSession: AuthSession?
    private(set) var saveCount = 0
    private(set) var clearCount = 0
    private let saveError: Error?

    init(savedSession: AuthSession? = nil, saveError: Error? = nil) {
        self.savedSession = savedSession
        self.saveError = saveError
    }

    func load() async throws -> AuthSession? {
        savedSession
    }

    func save(_ session: AuthSession) async throws {
        saveCount += 1
        if let saveError { throw saveError }
        savedSession = session
    }

    func clear() async throws {
        clearCount += 1
        savedSession = nil
    }
}

@MainActor
private final class RecordingServerPreferenceStore: ServerPreferenceStoring {
    var savedURL: URL?

    init(savedURL: URL? = nil) {
        self.savedURL = savedURL
    }

    func load() -> URL? { savedURL }

    func save(_ serverURL: URL) {
        savedURL = serverURL
    }
}

@MainActor
private final class RecordingNsfwPreferenceStore: NsfwPreferenceStoring {
    var savedValues: [UUID: Bool]

    init(savedValues: [UUID: Bool] = [:]) {
        self.savedValues = savedValues
    }

    func load(for userID: UUID) -> Bool {
        savedValues[userID] ?? false
    }

    func save(_ allowsNsfwContent: Bool, for userID: UUID) {
        savedValues[userID] = allowsNsfwContent
    }
}

private final class FailingHTTPDataLoader: HTTPDataLoading, @unchecked Sendable {
    let error: Error

    init(error: Error) {
        self.error = error
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        throw error
    }
}
