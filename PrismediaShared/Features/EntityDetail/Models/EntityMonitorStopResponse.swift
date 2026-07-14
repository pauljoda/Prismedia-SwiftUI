import Foundation

public struct EntityMonitorStopResponse: Decodable, Equatable, Sendable {
    public let entityPruned: Bool
}
