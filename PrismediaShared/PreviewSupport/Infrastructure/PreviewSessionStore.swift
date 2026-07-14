import Foundation

private final class PreviewSessionStore: SessionStoring {
    private var session: AuthSession?

    init(session: AuthSession?) {
        self.session = session
    }

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

@MainActor
func makePreviewSessionStore(session: AuthSession?) -> some SessionStoring {
    PreviewSessionStore(session: session)
}
