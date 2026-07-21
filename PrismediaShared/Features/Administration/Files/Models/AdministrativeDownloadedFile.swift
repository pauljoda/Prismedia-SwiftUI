import Foundation

public struct AdministrativeDownloadedFile: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let localURL: URL
    public let suggestedFileName: String

    public init(localURL: URL, suggestedFileName: String) {
        id = UUID()
        self.localURL = localURL
        self.suggestedFileName = suggestedFileName
    }
}
