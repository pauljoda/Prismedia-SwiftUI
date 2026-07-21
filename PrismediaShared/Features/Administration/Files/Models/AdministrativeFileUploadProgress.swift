import Foundation

public struct AdministrativeFileUploadProgress: Hashable, Sendable {
    public let completed: Int
    public let total: Int
    public let currentPath: String?

    public var fraction: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }
}
