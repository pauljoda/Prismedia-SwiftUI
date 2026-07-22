import Foundation

struct EntityChildMonitoringItem: Identifiable, Equatable, Sendable {
    let entity: EntityThumbnail
    let state: EntityMonitorState

    var id: UUID { entity.id }

    var isOn: Bool? {
        guard let monitor = state.monitor else { return false }
        switch monitor.status {
        case .active, .deletingFiles:
            return true
        case .paused, .fulfilled, .stopping:
            return false
        default:
            return nil
        }
    }

    var canRetryCleanup: Bool {
        state.monitor?.status == .stopping
    }

    var cleanupCommand: EntityAcquisitionCommand? {
        guard canRetryCleanup, let monitorID = state.monitor?.id else { return nil }
        return .unmonitor(monitorID)
    }

    func command(to nextValue: Bool) -> EntityAcquisitionCommand? {
        if nextValue {
            if let monitor = state.monitor {
                switch monitor.status {
                case .paused, .fulfilled:
                    return .resume(monitor.id)
                case .active, .deletingFiles, .stopping:
                    return nil
                default:
                    return nil
                }
            }
            if state.canRequest { return .searchForRelease(entity.id) }
            if state.canMonitor { return .start(entity.id) }
            return nil
        }

        guard let monitor = state.monitor else { return nil }
        switch monitor.status {
        case .active, .paused, .fulfilled:
            return .unmonitor(monitor.id)
        case .deletingFiles, .stopping:
            return nil
        default:
            return nil
        }
    }
}
