import Foundation

public struct AdministrativeBulkJobResponse: Decodable, Sendable {
    public let enqueued: Int
    public let skipped: Int
}
