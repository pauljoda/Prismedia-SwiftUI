import Foundation

struct AdministrativeIdentifyQueueCandidateRequest: Encodable, Sendable {
    let provider: String
    let candidate: AdministrativeEntitySearchCandidate
}
