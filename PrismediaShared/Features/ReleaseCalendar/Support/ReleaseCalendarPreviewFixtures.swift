import Foundation

#if DEBUG
    enum ReleaseCalendarPreviewFixtures {
        static let day = ReleaseCalendarDatePolicy.date(from: "2026-08-14")!
        static let events: [ReleaseCalendarEvent] = (1...6).map { index in
            ReleaseCalendarEvent(
                entityID: UUID(uuidString: String(format: "aaaaaaaa-aaaa-aaaa-aaaa-%012d", index))!,
                monitorID: UUID(uuidString: String(format: "bbbbbbbb-bbbb-bbbb-bbbb-%012d", index))!,
                kind: .video,
                title: "Episode \(index)",
                parentEntityID: UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!,
                parentKind: .videoSeries,
                parentTitle: "Example Series",
                dateType: index.isMultiple(of: 2) ? .streamingRelease : .air,
                value: "2026-08-14",
                date: "2026-08-14",
                precision: .day,
                acquisitionStatus: .waitingForRelease,
                isSearchGate: index == 1,
                searchNotBefore: index == 1 ? "2026-08-16" : nil,
                isSearchEligible: false
            )
        }
        static let longTitleEvent = ReleaseCalendarEvent(
            entityID: UUID(uuidString: "dddddddd-dddd-dddd-dddd-dddddddddddd")!,
            monitorID: UUID(uuidString: "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee")!,
            kind: .movie,
            title: "An Unexpected Journey Across the Northern Mountains",
            dateType: .physicalRelease,
            value: "2026-08-14", date: "2026-08-14", precision: .day,
            isSearchGate: true, searchNotBefore: "2026-08-16", isSearchEligible: false)
    }
#endif
