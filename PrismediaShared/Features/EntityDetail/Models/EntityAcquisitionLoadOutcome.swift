import Foundation

enum EntityAcquisitionLoadOutcome: Equatable, Sendable {
    case content(EntityMonitorState)
    case failure(String)
    case cancelled
}
