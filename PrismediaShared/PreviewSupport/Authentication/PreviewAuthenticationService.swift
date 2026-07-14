#if DEBUG
    import Foundation

    @MainActor
    final class PreviewAuthenticationService: AuthenticationServicing {
        private let needsSetup: Bool

        init(needsSetup: Bool = false) {
            self.needsSetup = needsSetup
        }

        func probeServer(urlText: String) async throws -> (address: ServerAddress, setup: SetupStatusResponse) {
            (
                try ServerAddress(text: urlText),
                SetupStatusResponse(needsSetup: needsSetup, hasUsers: !needsSetup)
            )
        }

        func signIn(server: ServerAddress, username: String, password: String) async throws {}

        func completeFirstRunSetup(
            server: ServerAddress,
            username: String,
            password: String,
            displayName: String?
        ) async throws {}
    }
#endif
