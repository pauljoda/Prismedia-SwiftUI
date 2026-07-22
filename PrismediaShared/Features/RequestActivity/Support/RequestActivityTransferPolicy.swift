import Foundation

/// Maps download-client transfer states to friendly stage labels for the acquisition
/// download view, matching the web's transfer-stage policy.
public enum RequestActivityTransferPolicy {
    /// Friendly label for a client state; falls back to the raw state, or "Connecting…" when unknown.
    public static func stageLabel(for state: String?) -> String {
        guard let state = normalizedState(state) else { return "Connecting…" }
        return stageLabels[state.lowercased()] ?? state
    }

    /// Whether the client reports ongoing work rather than a settled transfer state.
    public static func isActive(_ state: String?) -> Bool {
        guard let state = normalizedState(state) else { return true }
        return !settledStates.contains(state.lowercased())
    }

    public static func tone(for state: String?) -> RequestActivityTone {
        guard let state = normalizedState(state)?.lowercased() else { return .searching }
        if failedStates.contains(state) { return .failed }
        if attentionStates.contains(state) { return .attention }
        if completedStates.contains(state) { return .done }
        if queuedStates.contains(state) { return .queued }
        if pausedStates.contains(state) { return .muted }
        return .downloading
    }

    public static func systemImage(for state: String?) -> String {
        switch tone(for: state) {
        case .failed: "exclamationmark.circle"
        case .attention: "exclamationmark.triangle"
        case .done: "checkmark.circle"
        case .queued, .searching: "hourglass"
        case .muted: "pause.circle"
        case .downloading, .cleanup: "arrow.down.circle"
        }
    }

    public static func isComplete(_ state: String?) -> Bool {
        guard let state = normalizedState(state)?.lowercased() else { return false }
        return completedStates.contains(state)
    }

    public static func expectsDownloadTelemetry(_ state: String?) -> Bool {
        guard let state = normalizedState(state)?.lowercased() else { return true }
        return downloadTelemetryStates.contains(state)
    }

    /// Swarm counts are meaningful for torrents, but the shared API reports zeroes for
    /// protocols that do not have peers. Only surface a zero-count swarm when another
    /// transfer field establishes that the client is torrent-backed.
    public static func showsSwarmTelemetry(_ transfer: RequestActivityTransfer) -> Bool {
        if transfer.seeds > 0 || transfer.peers > 0 || !transfer.pieceStates.isEmpty { return true }
        guard let state = normalizedState(transfer.state)?.lowercased() else { return false }
        return torrentSpecificStates.contains(state)
    }

    // External client state strings are matched only here for display. qBittorrent
    // remains the most detailed vocabulary; Transmission, SABnzbd, and slskd values
    // are normalized where their meaning is unambiguous.
    private static let stageLabels: [String: String] = [
        "allocating": "Allocating",
        "metadl": "Fetching metadata",
        "forcedmetadl": "Fetching metadata",
        "downloading": "Downloading",
        "inprogress": "Downloading",
        "forceddl": "Downloading",
        "stalleddl": "Stalled — looking for peers",
        "queueddl": "Queued",
        "queued": "Queued",
        "checkingdl": "Verifying",
        "checkingresumedata": "Verifying",
        "checking": "Verifying",
        "verifying": "Verifying",
        "repairing": "Repairing",
        "extracting": "Extracting",
        "moving": "Moving files",
        "pausing": "Pausing",
        "pauseddl": "Paused",
        "paused": "Paused",
        "stopped": "Paused",
        "uploading": "Seeding",
        "forcedup": "Seeding",
        "stalledup": "Seeding",
        "queuedup": "Seeding",
        "seeding": "Seeding",
        "checkingup": "Verifying",
        "pausedup": "Complete",
        "completed": "Download complete",
        "error": "Error",
        "failed": "Download failed",
        "missingfiles": "Missing files",
        "unknown": "Connecting…",
    ]

    private static let failedStates: Set<String> = ["error", "failed", "missingfiles"]
    private static let attentionStates: Set<String> = ["stalleddl"]
    private static let completedStates: Set<String> = ["completed", "pausedup"]
    private static let queuedStates: Set<String> = ["queued", "queueddl"]
    private static let pausedStates: Set<String> = ["paused", "pauseddl", "stopped"]
    private static let downloadTelemetryStates: Set<String> = [
        "allocating", "metadl", "forcedmetadl", "downloading", "inprogress", "forceddl",
        "queueddl", "queued",
    ]
    private static let settledStates =
        failedStates
        .union(attentionStates)
        .union(completedStates)
        .union(pausedStates)
    private static let torrentSpecificStates: Set<String> = [
        "allocating", "metadl", "forcedmetadl", "forceddl", "stalleddl", "queueddl",
        "checkingdl", "checkingresumedata", "pauseddl", "uploading", "forcedup", "stalledup",
        "queuedup", "checkingup", "pausedup", "missingfiles",
    ]

    private static func normalizedState(_ state: String?) -> String? {
        guard let state = state?.trimmingCharacters(in: .whitespacesAndNewlines), !state.isEmpty else {
            return nil
        }
        return state
    }
}
