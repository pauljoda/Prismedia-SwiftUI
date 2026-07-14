import Foundation

/// A signed-in Prismedia session: which server, the opaque session token, and the
/// user it belongs to. The token is a 90-day sliding session token — it renews
/// itself server-side on use, so there is no refresh flow. A 401 means the
/// session is dead and the user must sign in again.
public struct AuthSession: Codable, Equatable, Sendable {
    public let serverURL: URL
    public let accessToken: String
    public let user: UserAccount

    public init(serverURL: URL, accessToken: String, user: UserAccount) {
        self.serverURL = serverURL
        self.accessToken = accessToken
        self.user = user
    }

    public func replacingUser(_ user: UserAccount) -> AuthSession {
        AuthSession(serverURL: serverURL, accessToken: accessToken, user: user)
    }
}
