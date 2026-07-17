import Foundation

public enum AdministrativeFileArchiveError: LocalizedError, Sendable {
    case notReady
    case failed(String)

    public var errorDescription: String? {
        switch self {
        case .notReady: "The folder archive is not ready yet."
        case .failed(let message): message
        }
    }
}
