import Foundation

enum RequestActivityAcquisitionLifecyclePolicy {
    static func label(for status: AcquisitionStatus) -> String {
        status.rawValue == "pending"
            ? "Preparing Search"
            : RequestActivityStatusPolicy.label(for: status)
    }

    static func description(for status: AcquisitionStatus, message: String?) -> String? {
        if let message, !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return message
        }

        switch status.rawValue {
        case "pending": return "Preparing the acquisition before searching your indexers."
        case "searching": return "Querying your configured indexers for matching releases."
        case "awaiting-selection": return "Select a release below to start the download."
        case "queued": return "Waiting for the download client to begin transferring."
        case "downloading": return "Downloading the selected release."
        case "downloaded": return "The download is complete and ready to import."
        case "importing": return "Moving the downloaded files into your library."
        case "imported": return "The acquisition completed and is available in your library."
        case "failed": return "The acquisition failed."
        case "cancelled": return "This acquisition was cancelled."
        case "manual-import-required": return "The downloaded files need your approval before import."
        case "stopping": return "Removing the download and managed files."
        default:
            return RequestActivityStatusPolicy.isKnown(status)
                ? nil
                : "Waiting for Prismedia to finish this transition."
        }
    }

    static func primaryAction(
        for status: AcquisitionStatus,
        hasResumableImport: Bool
    ) -> RequestActivityAcquisitionAction? {
        guard !RequestActivityStatusPolicy.isTransitionLocked(status) else { return nil }

        switch status.rawValue {
        case "failed":
            return hasResumableImport
                ? .retryImport(allowFormatChange: false)
                : .research
        case "manual-import-required":
            return .retryImport(allowFormatChange: true)
        case "cancelled":
            return .research
        default:
            return nil
        }
    }

    static func secondaryActions(
        for status: AcquisitionStatus,
        hasResumableImport: Bool
    ) -> [RequestActivityAcquisitionAction] {
        guard !RequestActivityStatusPolicy.isTransitionLocked(status) else { return [] }

        switch status.rawValue {
        case "pending", "searching", "queued", "downloading", "downloaded":
            return [.cancel]
        case "awaiting-selection":
            return [.research, .cancel]
        case "failed":
            return hasResumableImport ? [.startOver] : []
        case "manual-import-required":
            return hasResumableImport ? [.research, .startOver] : [.research]
        default:
            return []
        }
    }

    static func content(for status: AcquisitionStatus) -> RequestActivityAcquisitionContent {
        guard !RequestActivityStatusPolicy.isTransitionLocked(status) else { return .locked }

        switch status.rawValue {
        case "pending": return .preparingSearch
        case "searching": return .searching
        case "queued", "downloading": return .download
        case "downloaded", "importing", "imported": return .files
        case "awaiting-selection", "manual-import-required": return .releases
        case "failed", "cancelled": return .lifecycleOnly
        default: return .lifecycleOnly
        }
    }

    static func showsReleasePicker(
        for status: AcquisitionStatus,
        hasResumableImport: Bool,
        hasCandidates: Bool
    ) -> Bool {
        guard !RequestActivityStatusPolicy.isTransitionLocked(status) else { return false }
        switch status.rawValue {
        case "awaiting-selection", "manual-import-required":
            return true
        case "failed":
            return !hasResumableImport && hasCandidates
        case "cancelled":
            return hasCandidates
        default:
            return false
        }
    }
}
