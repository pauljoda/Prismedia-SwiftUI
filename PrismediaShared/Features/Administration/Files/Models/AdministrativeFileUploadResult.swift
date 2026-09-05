import Foundation

public struct AdministrativeFileUploadResult: Hashable, Sendable {
    public let successfulPaths: [String]
    public let failures: [AdministrativeFileUploadFailure]
    public let scansQueued: Int
    /// True when processing stopped before all selected items had a confirmed outcome.
    public let isCancelled: Bool
}
