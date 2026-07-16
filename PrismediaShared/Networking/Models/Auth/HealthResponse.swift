import Foundation

public struct HealthResponse: Decodable, Hashable, Sendable {
    public let status: String
    public let runtime: String?

    public init(status: String, runtime: String? = nil) {
        self.status = status
        self.runtime = runtime
    }
}
