import Foundation

enum EntityAcquisitionLoadOutcome: Equatable, Sendable {
    case content(EntityAcquisitionPanelSnapshot)
    case failure(String)
    case cancelled
}
