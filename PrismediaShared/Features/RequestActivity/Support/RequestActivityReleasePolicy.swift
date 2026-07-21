import Foundation

/// Shared release-candidate rules mirrored from the web release table.
public enum RequestActivityReleasePolicy {
    /// Manual picks may override profile and identity scoring, but never a release
    /// Prismedia cannot safely queue.
    public static func canManuallyQueue(_ candidate: RequestActivityReleaseCandidate) -> Bool {
        !candidate.rejections.contains { nonQueueableRejections.contains($0.rawValue) }
    }

    /// Human-readable rejection summary ("wrong protocol, below cutoff").
    public static func rejectionText(_ candidate: RequestActivityReleaseCandidate) -> String {
        candidate.rejections
            .map { $0.rawValue.replacingOccurrences(of: "-", with: " ") }
            .joined(separator: ", ")
    }

    private static let nonQueueableRejections: Set<String> = [
        "unsupported-format",
        "wrong-protocol",
        "no-download-link",
        "blocklisted",
        "dangerous-content",
    ]
}
