import Foundation

public struct RequestActivityRemovalSummary: Equatable, Sendable {
    public let attempted: Int
    public let failures: [String]

    public init(attempted: Int, failures: [String]) {
        self.attempted = attempted
        self.failures = failures
    }

    public var succeeded: Int { max(0, attempted - failures.count) }

    public var message: String {
        let noun = attempted == 1 ? "download" : "downloads"
        let prefix = "Removed \(succeeded) of \(attempted) \(noun)."
        guard !failures.isEmpty else { return prefix }
        return "\(prefix) \(failures.joined(separator: "; "))"
    }
}
