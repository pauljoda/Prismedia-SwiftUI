import Foundation

final class HTTPMultipartInputStream: InputStream, @unchecked Sendable {
    private let segments: [HTTPMultipartStreamSegment]
    private var segmentIndex = 0
    private var dataOffset = 0
    private var fileStream: InputStream?
    private var currentStatus = Stream.Status.notOpen
    private var currentError: (any Error)?

    init(segments: [HTTPMultipartStreamSegment]) {
        self.segments = segments
        super.init(data: Data())
    }

    override func open() {
        guard currentStatus == .notOpen else { return }
        currentStatus = .open
    }

    override func close() {
        fileStream?.close()
        fileStream = nil
        currentStatus = .closed
    }

    override var hasBytesAvailable: Bool {
        currentStatus == .open && segmentIndex < segments.count
    }

    override var streamStatus: Stream.Status {
        currentStatus
    }

    override var streamError: (any Error)? {
        currentError
    }

    override func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        guard len > 0 else { return 0 }
        guard currentStatus == .open else { return currentStatus == .atEnd ? 0 : -1 }

        while segmentIndex < segments.count {
            switch segments[segmentIndex] {
            case .data(let data):
                let remaining = data.count - dataOffset
                if remaining == 0 {
                    advanceSegment()
                    continue
                }
                let count = min(len, remaining)
                data.withUnsafeBytes { rawBuffer in
                    guard let source = rawBuffer.bindMemory(to: UInt8.self).baseAddress else { return }
                    buffer.update(from: source.advanced(by: dataOffset), count: count)
                }
                dataOffset += count
                return count

            case .file(let url, _):
                if fileStream == nil {
                    guard let stream = InputStream(url: url) else {
                        fail(URLError(.fileDoesNotExist))
                        return -1
                    }
                    fileStream = stream
                    stream.open()
                }
                guard let fileStream else { return -1 }
                let count = fileStream.read(buffer, maxLength: len)
                if count > 0 { return count }
                if count < 0 {
                    fail(fileStream.streamError ?? URLError(.cannotOpenFile))
                    return -1
                }
                fileStream.close()
                self.fileStream = nil
                advanceSegment()
            }
        }

        currentStatus = .atEnd
        return 0
    }

    private func advanceSegment() {
        segmentIndex += 1
        dataOffset = 0
    }

    private func fail(_ error: any Error) {
        currentError = error
        currentStatus = .error
    }
}
