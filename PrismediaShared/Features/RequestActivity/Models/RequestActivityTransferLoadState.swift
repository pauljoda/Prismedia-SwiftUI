import Foundation

enum RequestActivityTransferLoadState: Equatable, Sendable {
    case preparing
    case current
    case stale
    case unavailable
}
