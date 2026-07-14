import Foundation

struct AdministrativeIdentifyQueueSearchRequest: Encodable, Sendable {
    let provider: String?
    let query: AdministrativeIdentifyQuery?
}
