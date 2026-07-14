import Foundation

public struct RequestActivityAcquisitionDetail: Decodable, Equatable, Sendable {
    public let summary: RequestActivityAcquisitionSummary
    public let candidates: [RequestActivityReleaseCandidate]

    public init(summary: RequestActivityAcquisitionSummary, candidates: [RequestActivityReleaseCandidate]) {
        self.summary = summary
        self.candidates = candidates
    }
}
