import Foundation

enum RequestActivityAcquisitionActionPlacementPolicy {
    static func visibleActions(
        from actions: [RequestActivityAcquisitionAction]
    ) -> [RequestActivityAcquisitionAction] {
        actions.filter { $0 != .cancel }
    }

    static func menuActions(
        from actions: [RequestActivityAcquisitionAction]
    ) -> [RequestActivityAcquisitionAction] {
        actions.filter { $0 == .cancel }
    }
}
