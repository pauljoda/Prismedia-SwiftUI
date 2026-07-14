import Foundation

public struct EntityMonitorState: Decodable, Equatable, Sendable {
    public let entityID: UUID
    public let canMonitor: Bool
    public let canRequest: Bool
    public let trackableProviders: [String]
    public let discoversChildren: Bool
    public let canSearchMissingChildren: Bool
    public let missingChildEntityKind: EntityKind?
    public let monitor: EntityMonitor?
    public let latestAcquisition: EntityAcquisitionSummary?

    private enum CodingKeys: String, CodingKey {
        case entityID = "entityId"
        case canMonitor
        case canRequest
        case trackableProviders
        case discoversChildren
        case canSearchMissingChildren
        case missingChildEntityKind
        case monitor
        case latestAcquisition
    }
}
