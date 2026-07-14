import Foundation

enum EntityAcquisitionPanelPhase: Equatable, Sendable {
    case loading
    case content(EntityMonitorState)
    case failure(String)
}
