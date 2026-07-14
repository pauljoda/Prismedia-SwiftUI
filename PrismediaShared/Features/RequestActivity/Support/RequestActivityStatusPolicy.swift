import Foundation

public enum RequestActivityStatusPolicy {
    public static func isKnown(_ status: AcquisitionStatus) -> Bool {
        knownStatuses.contains(status.rawValue)
    }

    public static func shouldPoll(_ status: AcquisitionStatus?) -> Bool {
        guard let status else { return false }
        guard isKnown(status) else { return true }
        return activeStatuses.contains(status.rawValue)
    }

    public static func isTransitionLocked(_ status: AcquisitionStatus) -> Bool {
        status.rawValue == "stopping" || !isKnown(status)
    }

    public static func label(for status: AcquisitionStatus) -> String {
        labels[status.rawValue] ?? "Updating"
    }

    public static func tone(for status: AcquisitionStatus) -> RequestActivityTone {
        switch status.rawValue {
        case "downloading", "downloaded", "importing": .downloading
        case "queued": .queued
        case "pending", "searching": .searching
        case "failed": .failed
        case "awaiting-selection", "manual-import-required": .attention
        case "imported": .done
        case "stopping": .cleanup
        case "cancelled": .muted
        default: .cleanup
        }
    }

    public static func systemImage(for status: AcquisitionStatus) -> String {
        switch status.rawValue {
        case "downloading", "downloaded", "importing": "arrow.down.circle"
        case "queued": "hourglass"
        case "pending", "searching", "awaiting-selection": "magnifyingglass"
        case "failed": "exclamationmark.circle"
        case "manual-import-required": "exclamationmark.triangle"
        case "imported": "checkmark.circle"
        case "stopping": "arrow.trianglehead.2.clockwise.rotate.90"
        case "cancelled": "xmark.circle"
        default: "arrow.trianglehead.2.clockwise.rotate.90"
        }
    }

    public static func description(for status: AcquisitionStatus, message: String?) -> String? {
        switch status.rawValue {
        case "awaiting-selection": "Select a release to start the download."
        case "pending": "Preparing to search…"
        case "searching": "Finding releases…"
        case "queued": "Waiting for a download slot."
        case "failed": message ?? "The download failed."
        case "downloaded": "Download complete; importing…"
        case "importing": "Importing into your library…"
        case "manual-import-required": message ?? "Manual import required."
        case "stopping": "Removing download and managed files…"
        default:
            isKnown(status) ? nil : "Waiting for Prismedia to finish this transition…"
        }
    }

    public static func primaryAction(
        for status: AcquisitionStatus,
        hasEntity: Bool
    ) -> RequestActivityPrimaryAction? {
        guard !isTransitionLocked(status) else { return nil }
        switch status.rawValue {
        case "awaiting-selection":
            return hasEntity ? RequestActivityPrimaryAction.chooseRelease : nil
        case "failed", "searching", "pending":
            return RequestActivityPrimaryAction.searchAgain
        default:
            return hasEntity ? RequestActivityPrimaryAction.view : nil
        }
    }

    public static func showsDeterminateProgress(_ status: AcquisitionStatus) -> Bool {
        ["downloading", "downloaded", "importing"].contains(status.rawValue)
    }

    private static let knownStatuses: Set<String> = Set(labels.keys)
    private static let activeStatuses: Set<String> = [
        "pending", "searching", "queued", "downloading", "downloaded", "importing", "stopping",
    ]
    private static let labels: [String: String] = [
        "pending": "Pending",
        "searching": "Searching",
        "awaiting-selection": "Choose Release",
        "queued": "Queued",
        "downloading": "Downloading",
        "downloaded": "Downloaded",
        "importing": "Importing",
        "imported": "Imported",
        "stopping": "Cleaning Up",
        "failed": "Failed",
        "cancelled": "Cancelled",
        "manual-import-required": "Manual Import",
    ]
}
