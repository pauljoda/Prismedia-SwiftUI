import Foundation

struct RequestActivityQueueReleaseRequest: Encodable, Sendable {
    let candidateId: UUID
}
