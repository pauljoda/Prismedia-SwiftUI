import Foundation

public struct EPUBBookmarkScope: Hashable, Sendable {
    public let serverURL: URL
    public let userID: UUID

    public init(serverURL: URL, userID: UUID) {
        self.serverURL = serverURL
        self.userID = userID
    }

    var storageKeyFragment: String {
        Data("\(serverURL.absoluteString)|\(userID.uuidString.lowercased())".utf8)
            .base64EncodedString()
    }
}
