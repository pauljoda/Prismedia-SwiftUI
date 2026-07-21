import Foundation

public struct AdministrativeFileUploadFailure: Identifiable, Hashable, Sendable {
    public let relativePath: String
    public let message: String
    public var id: String { relativePath }
}
