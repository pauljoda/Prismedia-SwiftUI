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

    public init(
        id: UUID,
        type: String,
        status: String,
        progress: Int,
        message: String?,
        targetKind: String?,
        targetID: String?,
        targetLabel: String?,
        createdAt: Date,
        startedAt: Date?,
        finishedAt: Date?
    ) {
        self.id = id
        self.type = type
        self.status = status
        self.progress = progress
        self.message = message
        self.targetKind = targetKind
        self.targetID = targetID
        self.targetLabel = targetLabel
        self.createdAt = createdAt
        self.startedAt = startedAt
        self.finishedAt = finishedAt
    }

    enum CodingKeys: String, CodingKey {
        case id, type, status, progress, message, targetKind
        case targetID = "targetId"
        case targetLabel, createdAt, startedAt, finishedAt
    }

    public var isCancellable: Bool {
        ["active", "waiting", "delayed", "queued", "running"].contains(status.lowercased())
    }
}
