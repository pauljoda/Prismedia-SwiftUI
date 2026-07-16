import Foundation

public struct SearchHubFilterState: Equatable, Hashable, Sendable {
    public var selectedKinds: Set<EntityKind>
    public var minimumRating: Int?
    public var dateFrom: Date?
    public var dateTo: Date?

    public init(
        selectedKinds: Set<EntityKind> = SearchHubKindCatalog.allKinds,
        minimumRating: Int? = nil,
        dateFrom: Date? = nil,
        dateTo: Date? = nil
    ) {
        self.selectedKinds = selectedKinds.isEmpty ? SearchHubKindCatalog.allKinds : selectedKinds
        self.minimumRating = minimumRating
        self.dateFrom = dateFrom
        self.dateTo = dateTo
    }

    public var isDefault: Bool {
        selectedKinds == SearchHubKindCatalog.allKinds
            && minimumRating == nil
            && dateFrom == nil
            && dateTo == nil
    }

    public var activeFilterCount: Int {
        (selectedKinds == SearchHubKindCatalog.allKinds ? 0 : 1)
            + (minimumRating == nil ? 0 : 1)
            + (dateFrom == nil ? 0 : 1)
            + (dateTo == nil ? 0 : 1)
    }

    public mutating func toggle(_ kind: EntityKind) {
        if selectedKinds.contains(kind) {
            guard selectedKinds.count > 1 else { return }
            selectedKinds.remove(kind)
        } else {
            selectedKinds.insert(kind)
        }
    }

    public mutating func setDateFrom(_ date: Date?) {
        dateFrom = date.map { Calendar.autoupdatingCurrent.startOfDay(for: $0) }
        if let dateFrom, let dateTo, dateFrom > dateTo {
            self.dateTo = dateFrom
        }
    }

    public mutating func setDateTo(_ date: Date?) {
        dateTo = date.map { Calendar.autoupdatingCurrent.startOfDay(for: $0) }
        if let dateFrom, let dateTo, dateTo < dateFrom {
            self.dateFrom = dateTo
        }
    }

    public mutating func reset() {
        self = SearchHubFilterState()
    }

    public func includes(_ item: EntityThumbnail, calendar: Calendar = .autoupdatingCurrent) -> Bool {
        guard selectedKinds.contains(item.kind) else { return false }
        if let minimumRating, (item.rating ?? Int.min) < minimumRating { return false }

        if let dateFrom {
            guard let createdAt = item.createdAt, createdAt >= calendar.startOfDay(for: dateFrom) else {
                return false
            }
        }

        if let dateTo {
            guard let createdAt = item.createdAt else { return false }
            let start = calendar.startOfDay(for: dateTo)
            guard let exclusiveEnd = calendar.date(byAdding: .day, value: 1, to: start) else {
                return false
            }
            if createdAt >= exclusiveEnd { return false }
        }

        return true
    }
}
