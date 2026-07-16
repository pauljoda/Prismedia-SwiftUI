import Foundation

public struct AdministrativeDatabaseRestoreStatus: Decodable, Hashable, Sendable {
    public let restorePending: Bool
    public let restoreFailed: Bool
    public let error: String?

    public init(restorePending: Bool, restoreFailed: Bool, error: String?) {
        self.restorePending = restorePending
        self.restoreFailed = restoreFailed
        self.error = error
    }
}
