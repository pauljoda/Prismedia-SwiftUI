import Foundation

/// Persists the signed-in session. Sessions are per-device on the server (each
/// login registers a device entry), so this is device-local Keychain storage —
/// tokens are deliberately not synced across devices.
@MainActor
public protocol SessionStoring {
    func load() async throws -> AuthSession?
    func save(_ session: AuthSession) async throws
    func clear() async throws
}
