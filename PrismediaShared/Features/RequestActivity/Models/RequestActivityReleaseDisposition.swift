import Foundation

enum RequestActivityReleaseDisposition: Equatable, Sendable {
    case eligible
    case overridable
    case unavailable
    case blocklisted
}
