import Foundation

public struct AdministrativeIdentifyBulkAcceptedResponse: Decodable, Hashable, Sendable {
    public let requested: Int
    public let enqueued: Int
}
