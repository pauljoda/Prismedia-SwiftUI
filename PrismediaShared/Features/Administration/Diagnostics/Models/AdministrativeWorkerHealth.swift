import Foundation

public struct AdministrativeWorkerHealth: Decodable, Hashable, Sendable {
    public let status: String
    public let workerID: String?
    public let lastSeenAt: Date?
    public let staleAfterSeconds: Int

    public init(status: String, workerID: String?, lastSeenAt: Date?, staleAfterSeconds: Int) {
        self.status = status
        self.workerID = workerID
        self.lastSeenAt = lastSeenAt
        self.staleAfterSeconds = staleAfterSeconds
    }

    private enum CodingKeys: String, CodingKey {
        case status, lastSeenAt, staleAfterSeconds
        case workerID = "workerId"
    }
}
