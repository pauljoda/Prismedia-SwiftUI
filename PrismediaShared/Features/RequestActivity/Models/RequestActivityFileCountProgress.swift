import Foundation

struct RequestActivityFileCountProgress: Equatable, Sendable {
    let processed: Int
    let total: Int
}
