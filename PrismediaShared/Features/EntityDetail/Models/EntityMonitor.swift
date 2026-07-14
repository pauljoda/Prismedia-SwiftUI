import Foundation

public struct EntityMonitor: Decodable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let kind: EntityKind
    public let acquisitionID: UUID?
    public let status: EntityMonitorStatus
    public let title: String
    public let author: String?
    public let acquisitionStatus: AcquisitionStatus?
    public let createdAt: Date
    public let updatedAt: Date
    public let entityID: UUID?
    public let preset: String

    private enum CodingKeys: String, CodingKey {
        case id
        case kind
        case acquisitionID = "acquisitionId"
        case status
        case title
        case author
        case acquisitionStatus
        case createdAt
        case updatedAt
        case entityID = "entityId"
        case preset
    }
}
