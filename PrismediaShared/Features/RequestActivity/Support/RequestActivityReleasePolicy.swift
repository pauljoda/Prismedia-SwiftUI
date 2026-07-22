import Foundation

/// Shared release-candidate rules mirrored from the web release table.
public enum RequestActivityReleasePolicy {
    static func disposition(
        of candidate: RequestActivityReleaseCandidate
    ) -> RequestActivityReleaseDisposition {
        let reasons = Set(candidate.rejections.map(\.rawValue))
        if reasons.contains("blocklisted") { return .blocklisted }
        if !reasons.isDisjoint(with: unavailableRejections) { return .unavailable }
        return candidate.accepted ? .eligible : .overridable
    }

    /// Manual picks may override profile and identity scoring, but never a release
    /// Prismedia cannot safely queue.
    public static func canManuallyQueue(_ candidate: RequestActivityReleaseCandidate) -> Bool {
        [.eligible, .overridable].contains(disposition(of: candidate))
    }

    /// Human-readable rejection summary ("wrong protocol, below cutoff").
    public static func rejectionText(_ candidate: RequestActivityReleaseCandidate) -> String {
        candidate.rejections
            .map { humanized($0.rawValue) }
            .joined(separator: ", ")
    }

    static func filteredCandidates(
        _ candidates: [RequestActivityReleaseCandidate],
        showsOnlyRelevant: Bool
    ) -> [RequestActivityReleaseCandidate] {
        guard showsOnlyRelevant else { return candidates }
        let eligible = candidates.filter { disposition(of: $0) == .eligible }
        if !eligible.isEmpty { return eligible }
        return candidates.filter { disposition(of: $0) != .blocklisted }
    }

    static func sortedCandidates(
        _ candidates: [RequestActivityReleaseCandidate],
        by sort: RequestActivityReleaseSort
    ) -> [RequestActivityReleaseCandidate] {
        guard sort != .bestMatch else { return candidates }
        let originalOrder = Dictionary(
            uniqueKeysWithValues: candidates.enumerated().map { ($1.id, $0) }
        )

        return candidates.sorted { lhs, rhs in
            let ordered: Bool?
            switch sort {
            case .bestMatch:
                ordered = nil
            case .seedersDescending:
                ordered = order(lhs.seeders ?? 0, rhs.seeders ?? 0, ascending: false)
            case .seedersAscending:
                ordered = order(lhs.seeders ?? 0, rhs.seeders ?? 0, ascending: true)
            case .sizeDescending:
                ordered = order(lhs.sizeBytes, rhs.sizeBytes, ascending: false)
            case .sizeAscending:
                ordered = order(lhs.sizeBytes, rhs.sizeBytes, ascending: true)
            case .titleAscending:
                ordered = stringOrder(displayTitle(for: lhs), displayTitle(for: rhs), ascending: true)
            case .titleDescending:
                ordered = stringOrder(displayTitle(for: lhs), displayTitle(for: rhs), ascending: false)
            case .indexerAscending:
                ordered = stringOrder(lhs.indexerName, rhs.indexerName, ascending: true)
            case .indexerDescending:
                ordered = stringOrder(lhs.indexerName, rhs.indexerName, ascending: false)
            }
            return ordered ?? (originalOrder[lhs.id, default: 0] < originalOrder[rhs.id, default: 0])
        }
    }

    static func displayTitle(for candidate: RequestActivityReleaseCandidate) -> String {
        splitTitle(candidate.title).title
    }

    static func category(for candidate: RequestActivityReleaseCandidate) -> String? {
        splitTitle(candidate.title).category
    }

    static func categorySystemImage(for category: String?) -> String {
        let value = category?.lowercased() ?? ""
        if containsAny(value, ["audio", "music", "mp3", "flac", "audiobook", "m4b"]) {
            return "headphones"
        }
        if containsAny(value, ["book", "ebook", "comic", "magazine"]) { return "book.closed" }
        if containsAny(value, ["doc", "pdf", "epub", "text"]) { return "doc.text" }
        if containsAny(value, ["video", "movie", "tv", "film"]) { return "film" }
        return "tag"
    }

    static func protocolLabel(for candidate: RequestActivityReleaseCandidate) -> String {
        if candidate.protocol == .torrent { return "Torrent" }
        if candidate.protocol == .usenet { return "Usenet" }
        if candidate.protocol == .soulseek { return "Soulseek" }
        let label = humanized(candidate.protocol.rawValue).capitalized
        return label.isEmpty ? "Unknown Protocol" : label
    }

    static func validInfoURL(for candidate: RequestActivityReleaseCandidate) -> URL? {
        guard let rawValue = candidate.infoURL,
            let url = URL(string: rawValue),
            let scheme = url.scheme?.lowercased(),
            ["http", "https"].contains(scheme),
            url.host != nil
        else { return nil }
        return url
    }

    static func statusLabel(for candidate: RequestActivityReleaseCandidate) -> String {
        switch disposition(of: candidate) {
        case .eligible: "Eligible"
        case .overridable: "Review Required"
        case .unavailable: "Unavailable"
        case .blocklisted: "Blocked"
        }
    }

    static func statusSystemImage(for candidate: RequestActivityReleaseCandidate) -> String {
        switch disposition(of: candidate) {
        case .eligible: "checkmark.circle"
        case .overridable: "exclamationmark.triangle"
        case .unavailable: "nosign"
        case .blocklisted: "hand.raised"
        }
    }

    private static let unavailableRejections: Set<String> = [
        "unsupported-format",
        "wrong-protocol",
        "no-download-link",
        "dangerous-content",
    ]

    private static func splitTitle(_ rawTitle: String) -> (title: String, category: String?) {
        guard let marker = rawTitle.lastIndex(of: "»") else {
            return (normalizedWhitespace(rawTitle), nil)
        }
        let title = normalizedWhitespace(String(rawTitle[..<marker]))
        let category = normalizedWhitespace(String(rawTitle[rawTitle.index(after: marker)...]))
        return (
            title.isEmpty ? normalizedWhitespace(rawTitle) : title,
            category.isEmpty ? nil : category
        )
    }

    private static func normalizedWhitespace(_ value: String) -> String {
        value.split(whereSeparator: \Character.isWhitespace).joined(separator: " ")
    }

    private static func containsAny(_ value: String, _ terms: [String]) -> Bool {
        terms.contains(where: value.contains)
    }

    private static func humanized(_ value: String) -> String {
        value.replacingOccurrences(of: "-", with: " ")
    }

    private static func order<Value: Comparable>(
        _ lhs: Value,
        _ rhs: Value,
        ascending: Bool
    ) -> Bool? {
        guard lhs != rhs else { return nil }
        return ascending ? lhs < rhs : lhs > rhs
    }

    private static func stringOrder(_ lhs: String, _ rhs: String, ascending: Bool) -> Bool? {
        let comparison = lhs.localizedCaseInsensitiveCompare(rhs)
        guard comparison != .orderedSame else { return nil }
        return ascending ? comparison == .orderedAscending : comparison == .orderedDescending
    }
}
