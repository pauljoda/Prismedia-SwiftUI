import Foundation

public struct MusicLibrarySection: Identifiable, Sendable {
    public let title: String
    public let items: [EntityThumbnail]
    public var id: String { title }

    public static func sections(for items: [EntityThumbnail]) -> [Self] {
        sections(for: items, sort: nil, sortDescending: false)
    }

    public static func sections(
        for items: [EntityThumbnail],
        sort: EntityGridSort?
    ) -> [Self] {
        sections(for: items, sort: sort, sortDescending: false)
    }

    public static func sections(
        for items: [EntityThumbnail],
        sort: EntityGridSort?,
        sortDescending: Bool
    ) -> [Self] {
        guard sort == nil || sort == .title else {
            return items.isEmpty ? [] : [Self(title: "", items: items)]
        }

        let grouped = Dictionary(grouping: items) { item in
            guard let first = item.title.first, first.isLetter else { return "#" }
            return String(first).uppercased()
        }

        let descending = sort == .title && sortDescending
        var titles = grouped.keys.sorted()
        if descending { titles.reverse() }

        return titles.map { title in
            Self(
                title: title,
                items: grouped[title, default: []].sorted {
                    $0.title.localizedStandardCompare($1.title)
                        == (descending ? .orderedDescending : .orderedAscending)
                }
            )
        }
    }
}
