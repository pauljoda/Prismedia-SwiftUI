import Foundation

struct EntityChildAcquisitionActivityItem: Identifiable, Equatable, Sendable {
    let entity: EntityThumbnail
    let state: EntityMonitorState

    var id: UUID { entity.id }
    var acquisition: EntityAcquisitionSummary? { state.latestAcquisition }

    var isPreparingMetadata: Bool {
        acquisition == nil
            && state.monitor?.status == .active
            && state.canRequest
            && entity.isWanted
    }

    var hasActivity: Bool {
        acquisition != nil || isPreparingMetadata
    }
}
