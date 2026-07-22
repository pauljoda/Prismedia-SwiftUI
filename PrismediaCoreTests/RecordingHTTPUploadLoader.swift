import Foundation

@testable import PrismediaCore

final class RecordingHTTPUploadLoader: HTTPUploadLoading, @unchecked Sendable {
    private let lock = NSLock()
    private let responseData: Data
    private(set) var request: URLRequest?
    private(set) var uploadedData = Data()

    init(responseJSON: String) {
        responseData = Data(responseJSON.utf8)
    }

    func upload(
        for request: URLRequest,
        body: HTTPMultipartUploadBody,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> (Data, URLResponse) {
        let stream = body.makeInputStream()
        stream.open()
        defer { stream.close() }

        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 4_096)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            if count < 0 { throw stream.streamError ?? URLError(.cannotOpenFile) }
            if count == 0 { break }
            data.append(buffer, count: count)
        }

        lock.withLock {
            self.request = request
            uploadedData = data
        }
        progress(0.5)
        progress(1)
        return (
            responseData,
            HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
        )
    }
}
