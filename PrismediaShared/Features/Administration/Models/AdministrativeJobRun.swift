import Foundation

public struct AdministrativeJobRun: Decodable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public let type: String
    public let status: String
    public let progress: Int
    public let message: String?
    public let targetKind: String?
    public let targetID: String?
    public let targetLabel: String?
    public let createdAt: Date
    public let startedAt: Date?
    public let finishedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, type, status, progress, message, targetKind
        case targetID = "targetId"
        case targetLabel, createdAt, startedAt, finishedAt
    }

    public var isCancellable: Bool { status == "queued" || status == "running" }
}
