import Foundation

public struct HTTPMultipartUploadFile: Equatable, Sendable {
    public let fieldName: String
    public let fileName: String
    public let contentType: String
    public let sourceURL: URL
    public let sizeBytes: Int64
    public let relativePathFieldName: String?
    public let relativePath: String?

    public init(
        fieldName: String,
        fileName: String,
        contentType: String,
        sourceURL: URL,
        sizeBytes: Int64,
        relativePathFieldName: String? = nil,
        relativePath: String? = nil
    ) {
        self.fieldName = fieldName
        self.fileName = fileName
        self.contentType = contentType
        self.sourceURL = sourceURL
        self.sizeBytes = sizeBytes
        self.relativePathFieldName = relativePathFieldName
        self.relativePath = relativePath
    }
}
