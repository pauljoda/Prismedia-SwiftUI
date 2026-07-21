import Foundation

/// Maps download-client transfer states to friendly stage labels for the acquisition
/// download view, matching the web's transfer-stage policy.
public enum RequestActivityTransferPolicy {
    /// Friendly label for a client state; falls back to the raw state, or "Connecting…" when unknown.
    public static func stageLabel(for state: String?) -> String {
        guard let state, !state.isEmpty else { return "Connecting…" }
        return stageLabels[state] ?? state
    }

    /// Whether the transfer is actively working (drives the activity indicator).
    public static func isActive(_ state: String?) -> Bool {
        guard let state else { return true }
        return !settledStates.contains(state)
    }

    // External qBittorrent state strings, matched only here purely for display labels.
    private static let stageLabels: [String: String] = [
        "allocating": "Allocating",
        "metaDL": "Fetching metadata",
        "forcedMetaDL": "Fetching metadata",
        "downloading": "Downloading",
        "forcedDL": "Downloading",
        "stalledDL": "Stalled — looking for peers",
        "queuedDL": "Queued",
        "checkingDL": "Verifying",
        "checkingResumeData": "Verifying",
        "moving": "Moving files",
        "pausedDL": "Paused",
        "uploading": "Seeding",
        "forcedUP": "Seeding",
        "stalledUP": "Seeding",
        "queuedUP": "Seeding",
        "checkingUP": "Verifying",
        "pausedUP": "Complete",
        "error": "Error",
        "missingFiles": "Missing files",
    ]

    private static let settledStates: Set<String> = [
        "pausedDL", "pausedUP", "error", "missingFiles",
    ]
}
