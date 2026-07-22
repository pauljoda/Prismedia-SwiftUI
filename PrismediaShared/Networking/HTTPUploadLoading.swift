import Foundation

public protocol HTTPUploadLoading: Sendable {
    func upload(
        for request: URLRequest,
        body: HTTPMultipartUploadBody,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> (Data, URLResponse)
}
