import Foundation

public struct EPUBChapter: Identifiable, Hashable, Sendable {
    public let id: String
    public let location: String
    public let fileURL: URL
    public let contentSize: Int

    public init(id: String, location: String, fileURL: URL, contentSize: Int = 0) {
        self.id = id
        self.location = location
        self.fileURL = fileURL
        self.contentSize = max(0, contentSize)
    }
}
