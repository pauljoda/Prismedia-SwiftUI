import Foundation

public struct AdministrativeBulkJobResponse: Decodable, Sendable {
    public let enqueued: Int
    public let skipped: Int

    public init(enqueued: Int, skipped: Int) {
        self.enqueued = enqueued
        self.skipped = skipped
    }
}
