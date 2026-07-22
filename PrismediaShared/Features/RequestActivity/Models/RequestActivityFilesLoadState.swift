import Foundation

struct RequestActivityFilesLoadState: Equatable, Sendable {
    enum Content: Equatable, Sendable {
        case initialLoading
        case initialFailure(String)
        case loaded(RequestActivityFiles)
        case waiting
        case empty
        case unavailable
    }

    private(set) var content: Content
    private(set) var consecutiveRefreshFailures = 0
    var showsStaleWarning: Bool { consecutiveRefreshFailures >= 3 && files != nil }
    var files: RequestActivityFiles? { if case let .loaded(files) = content { files } else { nil } }

    static func loaded(_ files: RequestActivityFiles) -> Self { .init(content: .loaded(files)) }
    static var initialLoading: Self { .init(content: .initialLoading) }

    mutating func recordRefreshFailure() { consecutiveRefreshFailures += 1 }
    mutating func recordSuccess(_ files: RequestActivityFiles) {
        content = .loaded(files)
        consecutiveRefreshFailures = 0
    }
    mutating func recordInitialFailure(_ message: String) { content = .initialFailure(message) }
    mutating func recordWaiting() { content = .waiting; consecutiveRefreshFailures = 0 }
    mutating func recordEmpty() { content = .empty; consecutiveRefreshFailures = 0 }
    mutating func recordUnavailable() { content = .unavailable; consecutiveRefreshFailures = 0 }
}
