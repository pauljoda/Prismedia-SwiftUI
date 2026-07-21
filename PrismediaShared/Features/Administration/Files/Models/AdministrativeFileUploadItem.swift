import Foundation

public struct AdministrativeFileUploadItem: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let localURL: URL
    public let relativePath: String
    public let securityScopeURL: URL?

    public init(localURL: URL, relativePath: String, securityScopeURL: URL? = nil) {
        id = UUID()
        self.localURL = localURL
        self.relativePath = relativePath
        self.securityScopeURL = securityScopeURL
    }
}
