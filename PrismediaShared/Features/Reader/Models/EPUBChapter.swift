import Foundation

public struct EPUBChapter: Identifiable, Hashable, Sendable {
    public let id: String
    public let location: String
    public let fileURL: URL

    public init(id: String, location: String, fileURL: URL) {
        self.id = id
        self.location = location
        self.fileURL = fileURL
    }
}
