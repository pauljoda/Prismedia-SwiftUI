import Foundation

public enum AcquisitionStatusPresentationPolicy {
    public static func presentation(
        for status: AcquisitionStatus?
    ) -> AcquisitionStatusPresentation {
        guard let status else {
            return AcquisitionStatusPresentation(
                label: "Wanted",
                systemImage: "bookmark.fill",
                tone: .wanted
            )
        }

        switch status.rawValue {
        case "waiting-for-release", "manual-search-required":
            return .init(
                label: "Waiting for release",
                systemImage: "calendar.badge.clock",
                tone: .queued
            )
        case "pending":
            return .init(label: "Pending", systemImage: "magnifyingglass", tone: .searching)
        case "searching":
            return .init(label: "Searching", systemImage: "magnifyingglass", tone: .searching)
        case "awaiting-selection":
            return .init(
                label: "Choose Release",
                systemImage: "magnifyingglass.circle",
                tone: .attention
            )
        case "queued":
            return .init(label: "Queued", systemImage: "hourglass", tone: .queued)
        case "waiting-for-download-client":
            return .init(label: "Waiting for client", systemImage: "hourglass", tone: .queued)
        case "downloading":
            return .init(label: "Downloading", systemImage: "arrow.down.circle", tone: .downloading)
        case "downloaded":
            return .init(label: "Downloaded", systemImage: "arrow.down.circle", tone: .downloading)
        case "importing":
            return .init(label: "Importing", systemImage: "arrow.down.circle", tone: .downloading)
        case "imported":
            return .init(label: "Imported", systemImage: "checkmark.circle", tone: .done)
        case "stopping":
            return .init(
                label: "Cleaning Up",
                systemImage: "arrow.trianglehead.2.clockwise.rotate.90",
                tone: .cleanup
            )
        case "failed":
            return .init(label: "Failed", systemImage: "exclamationmark.circle", tone: .failed)
        case "cancelled":
            return .init(label: "Cancelled", systemImage: "xmark.circle", tone: .muted)
        case "manual-import-required":
            return .init(
                label: "Manual Import",
                systemImage: "exclamationmark.triangle",
                tone: .attention
            )
        default:
            return .init(
                label: "Updating",
                systemImage: "arrow.trianglehead.2.clockwise.rotate.90",
                tone: .cleanup
            )
        }
    }
}
