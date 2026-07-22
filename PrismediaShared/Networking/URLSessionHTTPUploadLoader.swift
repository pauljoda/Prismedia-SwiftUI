import Foundation

public struct URLSessionHTTPUploadLoader: HTTPUploadLoading {
    public init() {}

    public func upload(
        for request: URLRequest,
        body: HTTPMultipartUploadBody,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> (Data, URLResponse) {
        let delegate = URLSessionHTTPUploadDelegate(body: body, progress: progress)
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        let session = URLSession(configuration: .ephemeral, delegate: delegate, delegateQueue: queue)
        var streamedRequest = request
        streamedRequest.httpBodyStream = body.makeInputStream()
        let task = session.uploadTask(withStreamedRequest: streamedRequest)

        defer { session.finishTasksAndInvalidate() }
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                delegate.begin(continuation)
                task.resume()
            }
        } onCancel: {
            task.cancel()
        }
    }
}
