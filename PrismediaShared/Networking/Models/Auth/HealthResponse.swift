import Foundation

/// Public readiness response of `GET /api/health`.
public struct HealthResponse: Decodable, Hashable, Sendable {
    // MARK: - Variables

    public let status: String
    public let runtime: String?
    /// Plain `X.Y.Z` server build version; absent on servers before 3.8.
    public let version: String?

    /// The parsed server build version, when the server reports one.
    public var serverVersion: PrismediaServerVersion? {
        PrismediaServerVersion(version)
    }

    // MARK: - Initializers

    public init(status: String, runtime: String? = nil, version: String? = nil) {
        self.status = status
        self.runtime = runtime
        self.version = version
    }
}
