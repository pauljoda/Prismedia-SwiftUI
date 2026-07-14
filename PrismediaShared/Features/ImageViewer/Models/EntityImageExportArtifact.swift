import Foundation

public struct EntityImageExportArtifact: Hashable, Sendable {
    public let fileURL: URL
    public let mimeType: String?

    public init(fileURL: URL, mimeType: String?) {
        precondition(fileURL.isFileURL, "Image export artifacts must be local files.")
        self.fileURL = fileURL
        self.mimeType = mimeType
    }
}
