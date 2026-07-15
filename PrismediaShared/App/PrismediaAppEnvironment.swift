import Foundation
import Observation

/// The app-wide composition and session root.
///
/// SwiftUI injects one retained instance through the typed environment. Views
/// observe only the properties they read, while feature work remains behind
/// focused service protocols.
@Observable
@MainActor
public final class PrismediaAppEnvironment {
    public private(set) var session: AuthSession?
    public private(set) var client: PrismediaAPIClient?
    public private(set) var isRestoringSession: Bool
    public private(set) var lastServerURL: URL?
    public private(set) var entityListRevision = 0
    public private(set) var contentRevision = 0
    public private(set) var allowsNsfwContent: Bool
    public let artworkLoader: any RemoteArtworkLoading
    public let artworkPaletteLoader: any ArtworkPaletteLoading
    public let imagePlaybackSession = EntityImagePlaybackSession()

    private let sessionStore: SessionStoring
    private let serverPreferenceStore: ServerPreferenceStoring
    private let nsfwPreferenceStore: NsfwPreferenceStoring
    private let clientFactory: (URL) -> PrismediaAPIClient

    public convenience init() {
        #if DEBUG
            let isUITesting = CommandLine.arguments.contains("-prismedia-ui-testing")
            let resetSession = CommandLine.arguments.contains("-prismedia-reset-session")
            let uiTestSession = PrismediaUITestBootstrap.session()
            let sessionStore: SessionStoring =
                isUITesting
                ? VolatileSessionStore()
                : KeychainSessionStore()
            let serverPreferenceStore: ServerPreferenceStoring =
                isUITesting
                ? VolatileServerPreferenceStore()
                : UserDefaultsServerPreferenceStore()
        #else
            let resetSession = false
            let uiTestSession: AuthSession? = nil
            let sessionStore: SessionStoring = KeychainSessionStore()
            let serverPreferenceStore: ServerPreferenceStoring = UserDefaultsServerPreferenceStore()
        #endif
        self.init(
            sessionStore: sessionStore,
            serverPreferenceStore: serverPreferenceStore,
            initialSession: uiTestSession,
            restoreOnInit: uiTestSession == nil,
            resetSessionOnInit: resetSession && uiTestSession == nil
        )
    }

    public init(
        sessionStore: SessionStoring,
        serverPreferenceStore: ServerPreferenceStoring = UserDefaultsServerPreferenceStore(),
        nsfwPreferenceStore: NsfwPreferenceStoring = UserDefaultsNsfwPreferenceStore(),
        clientFactory: @escaping (URL) -> PrismediaAPIClient = { PrismediaAPIClient(serverURL: $0) },
        artworkLoader: any RemoteArtworkLoading = RemoteArtworkPipeline.shared,
        artworkPaletteLoader: (any ArtworkPaletteLoading)? = nil,
        initialSession: AuthSession? = nil,
        restoreOnInit: Bool = true,
        resetSessionOnInit: Bool = false
    ) {
        self.sessionStore = sessionStore
        self.serverPreferenceStore = serverPreferenceStore
        self.nsfwPreferenceStore = nsfwPreferenceStore
        self.clientFactory = clientFactory
        self.artworkLoader = artworkLoader
        self.artworkPaletteLoader =
            artworkPaletteLoader
            ?? ArtworkPalettePipeline(artworkLoader: artworkLoader)

        let allowsNsfwContent =
            initialSession.map {
                $0.user.allowNsfw && nsfwPreferenceStore.load(for: $0.user.id)
            } ?? false
        session = initialSession
        self.allowsNsfwContent = allowsNsfwContent
        client = initialSession.map {
            clientFactory($0.serverURL)
                .allowingNsfwContent(allowsNsfwContent)
                .authenticated(with: $0.accessToken)
        }
        isRestoringSession = restoreOnInit
        lastServerURL = initialSession?.serverURL ?? serverPreferenceStore.load()

        if restoreOnInit {
            Task { [weak self] in
                guard let self else { return }
                if resetSessionOnInit {
                    try? await self.sessionStore.clear()
                }
                await self.restoreSession()
            }
        }
    }

    public func probeServer(
        urlText: String
    ) async throws -> (address: ServerAddress, setup: SetupStatusResponse) {
        let address = try ServerAddress(text: urlText)
        let setup = try await clientFactory(address.url).setupStatus()
        serverPreferenceStore.save(address.url)
        lastServerURL = address.url
        return (address, setup)
    }

    public func signIn(
        server: ServerAddress,
        username: String,
        password: String
    ) async throws {
        let response = try await clientFactory(server.url)
            .login(username: username, password: password, device: .current)
        try await adopt(
            AuthSession(
                serverURL: server.url,
                accessToken: response.accessToken,
                user: response.user
            ))
    }

    public func completeFirstRunSetup(
        server: ServerAddress,
        username: String,
        password: String,
        displayName: String?
    ) async throws {
        let response = try await clientFactory(server.url)
            .completeFirstRunSetup(
                username: username,
                password: password,
                displayName: displayName
            )
        try await adopt(
            AuthSession(
                serverURL: server.url,
                accessToken: response.accessToken,
                user: response.user
            ))
    }

    public func signOut() async {
        if let client {
            try? await client.logout()
        }

        try? await sessionStore.clear()
        session = nil
        client = nil
        allowsNsfwContent = false
    }

    public func entityDidMutate() {
        publishContentChange()
    }

    public func reloadContent() {
        publishContentChange()
    }

    public func setAllowsNsfwContent(_ allowsNsfwContent: Bool) {
        guard let session else { return }
        let allowed = session.user.allowNsfw && allowsNsfwContent
        guard allowed != self.allowsNsfwContent else { return }
        nsfwPreferenceStore.save(allowed, for: session.user.id)
        self.allowsNsfwContent = allowed
        client?.updateNsfwContentPreference(allowed)
        publishContentChange()
    }

    public func verifyCurrentSession() async {
        guard let client, let session else { return }

        do {
            let user = try await client.currentUser()
            let refreshed = session.replacingUser(user)
            guard refreshed != session else { return }

            self.session = refreshed
            allowsNsfwContent = storedPreference(for: refreshed.user)
            self.client?.updateNsfwContentPreference(allowsNsfwContent)
            self.client = configuredClient(for: refreshed)
            try? await sessionStore.save(refreshed)
        } catch let error as PrismediaAPIError where error.isAuthenticationFailure {
            try? await sessionStore.clear()
            self.session = nil
            self.client = nil
            allowsNsfwContent = false
        } catch {
            // A transient server failure must not discard a valid local session.
        }
    }

    public func restoreSession() async {
        isRestoringSession = true
        defer { isRestoringSession = false }

        do {
            let stored = try await sessionStore.load()
            session = stored
            allowsNsfwContent = stored.map { storedPreference(for: $0.user) } ?? false
            client = stored.map(configuredClient(for:))
        } catch {
            session = nil
            client = nil
            allowsNsfwContent = false
        }
    }

    private func adopt(_ newSession: AuthSession) async throws {
        do {
            try await sessionStore.save(newSession)
        } catch {
            // A successful server login must still enter the app when a local
            // development build cannot access Keychain. Keep the token only in
            // memory; the next launch will ask the person to sign in again.
            #if DEBUG
                print("Prismedia session could not be persisted securely: \(error.localizedDescription)")
            #endif
        }
        serverPreferenceStore.save(newSession.serverURL)
        lastServerURL = newSession.serverURL
        session = newSession
        allowsNsfwContent = storedPreference(for: newSession.user)
        client = configuredClient(for: newSession)
    }

    private func storedPreference(for user: UserAccount) -> Bool {
        user.allowNsfw && nsfwPreferenceStore.load(for: user.id)
    }

    private func configuredClient(for session: AuthSession) -> PrismediaAPIClient {
        clientFactory(session.serverURL)
            .allowingNsfwContent(allowsNsfwContent)
            .authenticated(with: session.accessToken)
    }

    private func publishContentChange() {
        entityListRevision &+= 1
        contentRevision &+= 1
    }
}
