import Foundation

public struct RequestActivityFiles: Decodable, Equatable, Sendable {
    public let imported: Bool
    public let files: [RequestActivityFile]

    public init(imported: Bool, files: [RequestActivityFile]) {
        self.imported = imported
        self.files = files
    }
}
