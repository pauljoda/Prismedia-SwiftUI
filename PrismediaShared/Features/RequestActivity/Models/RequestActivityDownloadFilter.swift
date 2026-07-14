import Foundation

public struct RequestActivityDownloadFilter: Hashable, Sendable {
    public var query: String
    public var status: RequestActivityStatusFilter
    public var kind: EntityKind?
    public var sort: RequestActivitySort

    public init(
        query: String = "",
        status: RequestActivityStatusFilter = .all,
        kind: EntityKind? = nil,
        sort: RequestActivitySort = .updatedNewest
    ) {
        self.query = query
        self.status = status
        self.kind = kind
        self.sort = sort
    }

    public func apply(to downloads: [RequestActivityDownload]) -> [RequestActivityDownload] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered = downloads.filter { item in
            let matchesText =
                needle.isEmpty
                || item.title.localizedCaseInsensitiveContains(needle)
                || item.author?.localizedCaseInsensitiveContains(needle) == true
                || item.series?.localizedCaseInsensitiveContains(needle) == true
                || item.clientName?.localizedCaseInsensitiveContains(needle) == true
            return matchesText
                && status.matches(item.status)
                && (kind == nil || kind == item.kind)
        }
        switch sort {
        case .updatedNewest:
            return filtered.sorted { $0.updatedAt > $1.updatedAt }
        case .title:
            return filtered.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
        case .progress:
            return filtered.sorted { ($0.progress ?? -1) > ($1.progress ?? -1) }
        }
    }
}
