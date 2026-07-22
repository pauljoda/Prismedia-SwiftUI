import Foundation

public struct RequestActivityManualUploadFile: Equatable, Identifiable, Sendable {
    public let id: String
    public let url: URL
    public let fileName: String
    public let relativePath: String
    public let sizeBytes: Int64
    public let contentType: String

    public init(
        url: URL,
        fileName: String,
        relativePath: String? = nil,
        sizeBytes: Int64,
        contentType: String = "application/octet-stream"
    ) {
        self.url = url
        self.fileName = fileName
        self.relativePath = relativePath ?? fileName
        self.sizeBytes = sizeBytes
        self.contentType = contentType
        id = "\(url.absoluteString)|\(self.relativePath)"
    }
}
