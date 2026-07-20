import Foundation

/// The entity acquisition panel's loaded slice: the monitor/eligibility state plus the
/// latest acquisition detail backing the entity (mirroring the web's paired
/// monitor-state and acquisition-for-entity reads).
struct EntityAcquisitionPanelSnapshot: Equatable, Sendable {
    let state: EntityMonitorState
    let latestAcquisition: RequestActivityAcquisitionDetail?
}
