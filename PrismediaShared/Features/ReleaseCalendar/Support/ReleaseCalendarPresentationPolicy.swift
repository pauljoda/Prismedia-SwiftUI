import Foundation

public enum ReleaseCalendarPresentationPolicy {
    public static func title(for event: ReleaseCalendarEvent) -> String {
        guard let parent = event.parentTitle?.trimmingCharacters(in: .whitespacesAndNewlines),
            !parent.isEmpty
        else { return event.title }
        return "\(parent) · \(event.title)"
    }

    public static func entityLink(for event: ReleaseCalendarEvent) -> EntityLink {
        EntityLink(
            entityID: event.entityID,
            kind: event.kind,
            parentEntityID: event.parentEntityID,
            parentKind: event.parentKind
        )
    }

    public static func groupedByDay(
        _ events: [ReleaseCalendarEvent],
        calendar: Calendar = .current
    ) -> [Date: [ReleaseCalendarEvent]] {
        Dictionary(grouping: events) { event in
            ReleaseCalendarDatePolicy.date(from: event.date, calendar: calendar) ?? .distantPast
        }
        .mapValues { events in
            events.sorted {
                ($0.dateType.milestoneOrder, title(for: $0))
                    < ($1.dateType.milestoneOrder, title(for: $1))
            }
        }
    }
}
