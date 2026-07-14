import Foundation

public enum RequestActivityWantedPolicy {
    public static func isTransitionLocked(
        monitorStatus: EntityMonitorStatus,
        acquisitionStatus: AcquisitionStatus?
    ) -> Bool {
        let monitorLocked =
            monitorStatus == .deletingFiles
            || monitorStatus == .stopping
            || !knownMonitorStatuses.contains(monitorStatus.rawValue)
        let acquisitionLocked = acquisitionStatus.map(RequestActivityStatusPolicy.isTransitionLocked) ?? false
        return monitorLocked || acquisitionLocked
    }

    public static func statusLabel(
        for item: RequestActivityWantedItem,
        list: RequestActivityWantedList
    ) -> String {
        if let status = item.acquisitionStatus {
            return RequestActivityStatusPolicy.label(for: status)
        }
        switch item.monitorStatus {
        case .deletingFiles: return "Deleting Files"
        case .stopping: return "Stopping"
        default:
            guard knownMonitorStatuses.contains(item.monitorStatus.rawValue) else { return "Updating" }
            return list == .missing ? "Missing" : "Cutoff Unmet"
        }
    }

    public static func description(
        monitorStatus: EntityMonitorStatus,
        acquisitionStatus: AcquisitionStatus?,
        list: RequestActivityWantedList
    ) -> String {
        guard isTransitionLocked(monitorStatus: monitorStatus, acquisitionStatus: acquisitionStatus) else {
            return list == .missing
                ? "Watching for a release…"
                : "Owned copy is below the quality cutoff — upgrading."
        }
        if monitorStatus == .deletingFiles {
            return "Removing managed files before monitoring resumes…"
        }
        if monitorStatus == .stopping || acquisitionStatus?.rawValue == "stopping" {
            return "Removing pending work and wanted state…"
        }
        return "Waiting for Prismedia to finish this transition…"
    }

    private static let knownMonitorStatuses: Set<String> = [
        EntityMonitorStatus.active.rawValue,
        EntityMonitorStatus.paused.rawValue,
        EntityMonitorStatus.deletingFiles.rawValue,
        EntityMonitorStatus.stopping.rawValue,
        EntityMonitorStatus.fulfilled.rawValue,
    ]
}
