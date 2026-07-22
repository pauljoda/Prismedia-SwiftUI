import Foundation

final class URLSessionHTTPUploadDelegate: NSObject, URLSessionDataDelegate, @unchecked Sendable {
    private let body: HTTPMultipartUploadBody
    private let progress: @Sendable (Double) -> Void
    private let lock = NSLock()
    private var responseData = Data()
    private var response: URLResponse?
    private var continuation: CheckedContinuation<(Data, URLResponse), any Error>?
    private var finished = false

    init(body: HTTPMultipartUploadBody, progress: @escaping @Sendable (Double) -> Void) {
        self.body = body
        self.progress = progress
    }

    func begin(_ continuation: CheckedContinuation<(Data, URLResponse), any Error>) {
        lock.withLock { self.continuation = continuation }
    }

    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) {
        lock.withLock { self.response = response }
        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        lock.withLock { responseData.append(data) }
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    ) {
        let expected = totalBytesExpectedToSend > 0 ? totalBytesExpectedToSend : body.contentLength
        guard expected > 0 else { return }
        progress(min(max(Double(totalBytesSent) / Double(expected), 0), 1))
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        needNewBodyStream completionHandler: @escaping (InputStream?) -> Void
    ) {
        completionHandler(body.makeInputStream())
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        let completion: (CheckedContinuation<(Data, URLResponse), any Error>?, Data, URLResponse?) = lock.withLock {
            guard !finished else { return (nil, Data(), nil) }
            finished = true
            let value = (continuation, responseData, response)
            continuation = nil
            return value
        }
        guard let continuation = completion.0 else { return }
        if let error {
            continuation.resume(throwing: error)
        } else if let response = completion.2 {
            continuation.resume(returning: (completion.1, response))
        } else {
            continuation.resume(throwing: URLError(.badServerResponse))
        }
    }
}
