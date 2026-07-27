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
        AcquisitionStatusPresentationPolicy.presentation(for: status).label
    }

    public static func tone(for status: AcquisitionStatus) -> RequestActivityTone {
        switch AcquisitionStatusPresentationPolicy.presentation(for: status).tone {
        case .downloading: .downloading
        case .searching: .searching
        case .queued: .queued
        case .cleanup: .cleanup
        case .attention: .attention
        case .failed: .failed
        case .done: .done
        case .muted, .wanted: .muted
        }
    }

    public static func systemImage(for status: AcquisitionStatus) -> String {
        AcquisitionStatusPresentationPolicy.presentation(for: status).systemImage
    }

    public static func description(for status: AcquisitionStatus, message: String?) -> String? {
        switch status.rawValue {
        case "awaiting-selection": "Select a release to start the download."
        case "pending": "Preparing to search…"
        case "searching": "Finding releases…"
        case "queued": "Waiting for a download slot."
        case "waiting-for-download-client": "Waiting for the download client to become available."
        case "failed": message ?? "The download failed."
        case "downloaded": "Download complete; importing…"
        case "importing": "Importing into your library…"
        case "manual-import-required": message ?? "Manual import required."
        case "waiting-for-release", "manual-search-required":
            "Searching will begin when the configured release milestone is reached."
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
        case "failed", "searching", "pending", "waiting-for-release", "manual-search-required":
            return RequestActivityPrimaryAction.searchAgain
        default:
            return hasEntity ? RequestActivityPrimaryAction.view : nil
        }
    }

    public static func showsDeterminateProgress(_ status: AcquisitionStatus) -> Bool {
        ["downloading", "downloaded", "importing"].contains(status.rawValue)
    }

    private static let knownStatuses: Set<String> = [
        "pending",
        "waiting-for-release",
        "manual-search-required",
        "searching",
        "awaiting-selection",
        "queued",
        "waiting-for-download-client",
        "downloading",
        "downloaded",
        "importing",
        "imported",
        "stopping",
        "failed",
        "cancelled",
        "manual-import-required",
    ]
    private static let activeStatuses: Set<String> = [
        "pending", "searching", "queued", "waiting-for-download-client", "downloading", "downloaded",
        "importing", "stopping",
    ]
}
