import Foundation

enum EntityAcquisitionPanelPhase: Equatable, Sendable {
    case loading
    case content(EntityAcquisitionPanelSnapshot)
    case failure(String)
}
