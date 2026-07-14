#if DEBUG
    import Foundation

    /// Process-local storage for UI automation. This keeps authentication tests
    /// independent of simulator signing and Keychain entitlement state.
    @MainActor
    final class VolatileSessionStore: SessionStoring {
        private var session: AuthSession?

        func load() async throws -> AuthSession? {
            session
        }

        func save(_ session: AuthSession) async throws {
            self.session = session
        }

        func clear() async throws {
            session = nil
        }
    }
#endif
