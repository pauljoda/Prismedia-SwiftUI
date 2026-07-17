import Foundation

public struct AdministrativeFileUploadResult: Hashable, Sendable {
    public let successfulPaths: [String]
    public let failures: [AdministrativeFileUploadFailure]
    public let scansQueued: Int
}
