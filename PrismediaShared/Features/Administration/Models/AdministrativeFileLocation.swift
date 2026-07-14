import Foundation

public struct AdministrativeFileLocation: Hashable, Sendable {
    public let rootID: UUID
    public let rootLabel: String
    public let path: String

    public init(rootID: UUID, rootLabel: String, path: String) {
        self.rootID = rootID
        self.rootLabel = rootLabel
        self.path = path
    }
}
