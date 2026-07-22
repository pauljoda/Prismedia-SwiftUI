import Foundation

public struct HTTPMultipartUploadBody: Sendable {
    public let boundary: String
    let segments: [HTTPMultipartStreamSegment]

    public init(boundary: String = "PrismediaBoundary-\(UUID().uuidString)", files: [HTTPMultipartUploadFile]) {
        self.boundary = boundary
        segments = files.flatMap { file in
            var values: [HTTPMultipartStreamSegment] = [
                .data(Self.fileHeader(boundary: boundary, file: file)),
                .file(file.sourceURL, sizeBytes: file.sizeBytes),
                .data(Data("\r\n".utf8)),
            ]
            if let fieldName = file.relativePathFieldName,
                let relativePath = file.relativePath
            {
                values.append(.data(Self.textField(boundary: boundary, name: fieldName, value: relativePath)))
            }
            return values
        } + [.data(Data("--\(boundary)--\r\n".utf8))]
    }

    public var contentLength: Int64 {
        segments.reduce(0) { $0 + $1.sizeBytes }
    }

    func makeInputStream() -> InputStream {
        HTTPMultipartInputStream(segments: segments)
    }

    private static func fileHeader(boundary: String, file: HTTPMultipartUploadFile) -> Data {
        let disposition =
            "Content-Disposition: form-data; name=\"\(quoted(file.fieldName))\"; filename=\"\(quoted(file.fileName))\"\r\n"
        return Data(
            ("--\(boundary)\r\n" + disposition + "Content-Type: \(file.contentType)\r\n\r\n").utf8
        )
    }

    private static func textField(boundary: String, name: String, value: String) -> Data {
        Data(
            ("--\(boundary)\r\n"
                + "Content-Disposition: form-data; name=\"\(quoted(name))\"\r\n\r\n"
                + "\(value)\r\n").utf8
        )
    }

    private static func quoted(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "_")
            .replacingOccurrences(of: "\"", with: "_")
            .replacingOccurrences(of: "\r", with: "_")
            .replacingOccurrences(of: "\n", with: "_")
    }
}
